import 'dart:async';

import 'package:cities_offline_app/core/ui_kit/widgets/ai_turn_card/ai_turn_card.dart';
import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/mediator/domain/models/locality.dart';
import 'package:cities_offline_app/features/mediator/domain/repos/cities_repository.dart';
import 'package:cities_offline_app/features/voice_ai_game/services/city_info_service.dart';
import 'package:cities_offline_app/features/voice_ai_game/services/command_parser.dart';
import 'package:cities_offline_app/features/voice_ai_game/services/intent_lexemes.dart';
import 'package:cities_offline_app/features/voice_ai_game/services/speech_service.dart';
import 'package:cities_offline_app/features/voice_ai_game/services/tts_service.dart';
import 'package:cities_offline_app/services/google_services/google_services_service.dart';
import 'package:cities_offline_app/services/localization/country_names.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/game_session.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/game_turn.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';
import '../cubit/voice_cubit.dart';
import '../widgets/voice_status_banner.dart';

class GameScreen extends StatefulWidget {
  final String sessionId;

  const GameScreen({required this.sessionId, super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final TextEditingController _controller = TextEditingController();
  VoiceCubit? _voiceCubit;
  bool _voiceLoopRunning = false;
  bool _disposed = false;
  bool _skipNextPrompt = false;
  bool _processingInput = false;
  String? _lastAiCityName;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    if (!await GoogleServicesService.hasGoogleServices()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppGlossary.voiceGameNotAvailable.translate())),
        );
      }
      return;
    }

    final session = getIt<GameBloc>().state.sessionById(widget.sessionId);
    if (session == null || !session.isVoiceEnabled) return;

    final uiLang = getIt<LanguageBloc>().state.language;
    final repo = getIt<CitiesRepository>();
    final tts = TtsService();
    final speech = SpeechService();
    final cityInfo = CityInfoService();

    await speech.initialize();
    await tts.initialize();

    final locale = await speech.currentLocale;
    final detected = CityInfoService.languageFromLocale(locale);
    final voiceLang = detected ?? uiLang;
    if (detected != null) {
      cityInfo.setLanguage(detected);
      await tts.setLanguage(CityInfoService.localeForTts(locale));
    }

    final parser = CommandParser(repo: repo, uiLanguage: voiceLang);

    final cubit = VoiceCubit(tts: tts, speech: speech, parser: parser);
    _voiceCubit = cubit;
    if (mounted) setState(() {});

    final ok = await cubit.initialize();
    if (!ok || !mounted) return;

    unawaited(_startVoiceLoop(widget.sessionId, cubit, cityInfo));
  }

  Future<void> _startVoiceLoop(
    String sessionId,
    VoiceCubit cubit,
    CityInfoService cityInfo,
  ) async {
    _voiceLoopRunning = true;

    while (_voiceLoopRunning && !_disposed) {
      if (_processingInput) {
        await Future.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final session = getIt<GameBloc>().state.sessionById(sessionId);
      if (session == null || session.status == GameStatus.finished) {
        if (session != null && _voiceLoopRunning) {
          await _handleVoiceGameOver(session, cubit, cityInfo);
        }
        break;
      }
      if (!session.isVoiceEnabled) break;

      final letter = session.expectedStartLetter;

      cubit.setStatusText(
        (letter.isEmpty ? AppGlossary.voiceAnyCity : AppGlossary.voiceTurnPrompt)
            .translate()
            .replaceAll('{letter}', letter),
      );

      if (_skipNextPrompt) {
        _skipNextPrompt = false;
      } else {
        cubit.setPhase(VoicePhase.speaking);
        await cubit.speak(cityInfo.turnPrompt(letter));
        if (_disposed) break;
      }

      cubit.setStatusText(AppGlossary.voiceListening.translate());
      final command = await cubit.listen();
      if (_disposed || _processingInput || !_voiceLoopRunning) break;

      switch (command.intent) {
        case VoiceIntent.cityName:
          if (command.rawText.isNotEmpty) {
            await _handleVoiceCityName(sessionId, command.rawText, cubit, cityInfo);
          }
        case VoiceIntent.hint:
          _processingInput = true;
          if (!mounted) return;
          getIt<GameBloc>().add(GameHintRequested(sessionId: sessionId));
          await _awaitAiThinking(sessionId);
          if (!mounted || _disposed) {
            _processingInput = false;
            return;
          }
          final s = getIt<GameBloc>().state.sessionById(sessionId);
          final lastTurn = s?.turns.lastOrNull;
          if (lastTurn != null && lastTurn.actor == GameTurnActor.ai && lastTurn.locality != null) {
            _skipNextPrompt = true;
            _lastAiCityName = lastTurn.locality!.matchedName;
            await cubit.speak(cityInfo.aiRespondedText(_lastAiCityName!, s!.expectedStartLetter));
          }
          _processingInput = false;
        case VoiceIntent.surrender:
          if (!mounted) return;
          getIt<GameBloc>().add(GameSurrenderRequested(sessionId: sessionId));
          _voiceLoopRunning = false;
        case VoiceIntent.score:
          final score = getIt<GameBloc>()
              .state
              .sessionById(sessionId)
              ?.score;
          if (score != null) {
            await cubit.speak(cityInfo.scoreText(score));
          }
        case VoiceIntent.repeat:
          final lastTurn = getIt<GameBloc>()
              .state
              .sessionById(sessionId)
              ?.turns
              .lastOrNull;
          if (lastTurn != null) {
            await cubit.speak(cityInfo.repeatTurnText(
              getIt<GameBloc>().state.sessionById(sessionId)?.expectedStartLetter ?? '?',
            ));
          }
        case VoiceIntent.population:
        case VoiceIntent.location:
        case VoiceIntent.type:
          final lastAccepted = getIt<GameBloc>()
              .state
              .sessionById(sessionId)
              ?.turns
              .where((t) => t.status == GameTurnStatus.accepted)
              .lastOrNull;
          if (lastAccepted?.locality != null) {
            final text = _infoText(
              command.intent,
              lastAccepted!.locality!,
              cityInfo,
            );
            await cubit.speak(text);
          }
        case VoiceIntent.unknown:
          final letter2 = getIt<GameBloc>()
              .state
              .sessionById(sessionId)
              ?.expectedStartLetter ?? '';
          cubit.setStatusText(
            AppGlossary.voiceNotUnderstood.translate().replaceAll('{letter}', letter2),
          );
          await cubit.speak(cityInfo.notUnderstoodText(letter2));
      }
    }

    _voiceLoopRunning = false;
  }

  Future<void> _handleVoiceCityName(
    String sessionId,
    String cityName,
    VoiceCubit cubit,
    CityInfoService cityInfo,
  ) async {
    _processingInput = true;

    final prevTurns = getIt<GameBloc>()
        .state
        .sessionById(sessionId)
        ?.turns
        .length ?? 0;

    getIt<GameBloc>().add(
      GameCitySubmitted(sessionId: sessionId, cityName: cityName),
    );

    final session = getIt<GameBloc>().state.sessionById(sessionId);
    if (session?.opponent == OpponentType.ai) {
      await getIt<GameBloc>().stream.firstWhere((state) {
        final s = state.sessionById(sessionId);
        if (s == null || s.status == GameStatus.finished) return true;
        return s.turns.length > prevTurns &&
            !(s.ai?.isAiThinking ?? false) &&
            (s.turns.last.status != GameTurnStatus.accepted ||
                s.turns.last.actor != GameTurnActor.user);
      });
    } else {
      await getIt<GameBloc>().stream.firstWhere((state) {
        final s = state.sessionById(sessionId);
        if (s == null) return true;
        return s.turns.length > prevTurns;
      });
    }

    if (!mounted || _disposed) {
      _processingInput = false;
      return;
    }

    final updated = getIt<GameBloc>().state.sessionById(sessionId);
    if (updated == null) {
      _processingInput = false;
      return;
    }

    if (updated.status == GameStatus.finished) {
      await _handleVoiceGameOver(updated, cubit, cityInfo);
      _processingInput = false;
      return;
    }

    final lastTurn = updated.turns.lastOrNull;
    if (lastTurn == null) {
      _processingInput = false;
      return;
    }

    if (lastTurn.status == GameTurnStatus.rejected) {
      final reason = _rejectReasonText(lastTurn);
      cubit.setStatusText(reason);
      await cubit.speak(reason);
      _processingInput = false;
      return;
    }

    if (lastTurn.actor == GameTurnActor.ai && lastTurn.locality != null) {
      _lastAiCityName = lastTurn.locality!.matchedName;
      final nextLetter = updated.expectedStartLetter;
      cubit.setStatusText(
        AppGlossary.voiceAiResponded.translate()
            .replaceAll('{city}', _lastAiCityName!)
            .replaceAll('{letter}', nextLetter),
      );
      _skipNextPrompt = true;
      await cubit.speak(cityInfo.aiRespondedText(_lastAiCityName!, nextLetter));
      _processingInput = false;
      return;
    }

    _processingInput = false;
  }

  Future<void> _handleVoiceGameOver(
    GameSession session,
    VoiceCubit cubit,
    CityInfoService cityInfo,
  ) async {
    if (!_voiceLoopRunning) return;
    if (session.winner == GameWinner.user) {
      cubit.setStatusText(AppGlossary.voiceYouWon.translate());
      await cubit.speak(cityInfo.youWonText());
    } else if (session.winner == GameWinner.ai) {
      cubit.setStatusText(AppGlossary.voiceAiWon.translate());
      await cubit.speak(cityInfo.aiWonText());
    } else {
      cubit.setStatusText(AppGlossary.voiceSurrenderAccepted.translate());
      await cubit.speak(cityInfo.surrenderAcceptedText());
    }
    _voiceLoopRunning = false;
  }

  Future<void> _showExitConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppGlossary.voiceExitTitle.translate()),
        content: Text(AppGlossary.voiceExitMessage.translate()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppGlossary.voiceExitCancel.translate()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppGlossary.voiceExitConfirm.translate()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _voiceLoopRunning = false;
      await _voiceCubit?.stop();
      if (mounted) context.pop();
    }
  }

  String _infoText(
    VoiceIntent intent,
    Locality locality,
    CityInfoService cityInfo,
  ) {
    return switch (intent) {
      VoiceIntent.population => cityInfo.populationText(locality),
      VoiceIntent.location => cityInfo.locationText(locality),
      VoiceIntent.type => cityInfo.typeText(locality),
      _ => '',
    };
  }

  Future<void> _awaitAiThinking(String sessionId) async {
    final bloc = getIt<GameBloc>();
    final session = bloc.state.sessionById(sessionId);
    if (session == null || session.opponent != OpponentType.ai) return;

    await bloc.stream.firstWhere(
      (state) {
        final s = state.sessionById(sessionId);
        return s == null || s.status == GameStatus.finished || !(s.ai?.isAiThinking ?? false);
      },
    );
  }

  bool get _canSubmit {
    return _controller.text.trim().isNotEmpty;
  }

  void _submitCity() {
    if (!_canSubmit) return;
    final value = _controller.text;
    _controller.clear();
    _voiceCubit?.stop();
    getIt<GameBloc>().add(
      GameCitySubmitted(sessionId: widget.sessionId, cityName: value),
    );
  }

  String _rejectReasonText(GameTurn turn) {
    final lang = getIt<LanguageBloc>().state.language;
    switch (turn.rejectReason) {
      case GameTurnRejectReason.emptyInput:
        return AppGlossary.rejectEmptyInput.translate();
      case GameTurnRejectReason.notFound:
        return AppGlossary.rejectNotFound.translate();
      case GameTurnRejectReason.alreadyUsed:
        return AppGlossary.rejectAlreadyUsed.translate();
      case GameTurnRejectReason.wrongStartLetter:
        final expected = turn.expectedStartLetter;
        if (expected == null || expected.isEmpty) {
          return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', '?');
        }
        return AppGlossary.rejectWrongStartLetter.translate().replaceAll('{letter}', expected);
      case GameTurnRejectReason.typeNotAllowed:
        final type = turn.locality?.cityType;
        final translated = type != null ? translateCityType(type) : '?';
        return AppGlossary.rejectTypeNotAllowed.translate().replaceAll('{type}', translated);
      case GameTurnRejectReason.oldNameNotAllowed:
        return AppGlossary.rejectOldNameNotAllowed.translate();
      case GameTurnRejectReason.belowMinPopulation:
        return AppGlossary.rejectBelowMinPopulation.translate();
      case GameTurnRejectReason.countryNotAllowed:
        final locality = turn.locality;
        if (locality == null || locality.countryCode.isEmpty) {
          return AppGlossary.rejectCountryNotAllowed.translate().replaceAll('{country}', '?');
        }
        final countryName = countryNames[locality.countryCode.toLowerCase()]?[lang] ?? locality.country;
        return AppGlossary.rejectCountryNotAllowed.translate().replaceAll('{country}', countryName);
      case null:
        return AppGlossary.rejectDeclined.translate();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _voiceLoopRunning = false;
    _voiceCubit?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<GameBloc>(),
      child: PopScope(
        canPop: _voiceCubit == null,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _showExitConfirmation();
        },
        child: Builder(
          builder: (context) {
            if (_voiceCubit != null) {
              return BlocProvider.value(
                value: _voiceCubit!,
                child: _buildBody(context),
              );
            }
            return _buildBody(context);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        actions: [
          IconButton(
            onPressed: () {
              context.pushNamed(
                RoutePaths.gameRulesForSession.name,
                pathParameters: {'sessionId': widget.sessionId},
              );
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: BlocListener<GameBloc, GameState>(
        listenWhen: (prev, curr) {
          final p = prev.sessionById(widget.sessionId);
          final c = curr.sessionById(widget.sessionId);
          return p != null && c != null && p.isVoiceEnabled != c.isVoiceEnabled;
        },
        listener: (context, state) {
          final session = state.sessionById(widget.sessionId);
          if (session == null) return;

          if (session.isVoiceEnabled && _voiceCubit == null) {
            _initVoice();
          } else if (!session.isVoiceEnabled && _voiceCubit != null) {
            _voiceLoopRunning = false;
            _voiceCubit?.cancel();
            _voiceCubit = null;
            setState(() {});
          }
        },
        child: SafeArea(
          child: BlocSelector<GameBloc, GameState, GameSession?>(
          selector: (state) => state.sessionById(widget.sessionId),
          builder: (context, session) {
            if (session == null) {
              return const Center(child: Text('Session not found'));
            }

            final isAiThinking = session.ai?.isAiThinking ?? false;
            final isActive = session.status == GameStatus.active;

            return Column(
              children: [
                if (_voiceCubit != null)
                  const VoiceStatusBanner(),
                if (session.status == GameStatus.finished)
                  _ResultBanner(
                    winner: session.winner,
                    opponent: session.opponent,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.score, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${AppGlossary.moves.translate()}: ${session.score}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: session.turns.isEmpty && !isAiThinking
                      ? Center(
                          child: Translator(
                            termin: AppGlossary.enterCity,
                            builder: (text) => Text(text),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: session.turns.length + (isAiThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (isAiThinking && index == 0) {
                              return const AiThinkingCard();
                            }

                            final adjustedIndex = isAiThinking ? index - 1 : index;
                            final turn = session.turns[session.turns.length - 1 - adjustedIndex];
                            return _GameTurnCard(
                              key: ValueKey(
                                '${turn.actor.name}-${turn.input}-$index-${turn.locality?.id ?? "none"}',
                              ),
                              turn: turn,
                              rejectReasonText: _rejectReasonText(turn),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, _, _) {
                      final canSubmit = _canSubmit && !isAiThinking && isActive;
                      return Row(
                        children: [
                          IconButton(
                            onPressed: !isAiThinking && isActive
                                ? () {
                                    getIt<GameBloc>().add(
                                      GameHintRequested(sessionId: widget.sessionId),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.help_outline),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _submitCity(),
                              enabled: !isAiThinking && isActive,
                              decoration: InputDecoration(
                                hintText: AppGlossary.enterCity.translate(),
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: canSubmit ? _submitCity : null,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
    ),
  ),
  );
  }
}

class _ResultBanner extends StatelessWidget {
  final GameWinner? winner;
  final OpponentType opponent;

  const _ResultBanner({
    required this.winner,
    required this.opponent,
  });

  @override
  Widget build(BuildContext context) {
    final term = switch (winner) {
      GameWinner.user => AppGlossary.youWon,
      GameWinner.ai => AppGlossary.aiWon,
      null => AppGlossary.gameFinished,
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Translator(
        termin: term,
        builder: (text) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _GameTurnName extends StatelessWidget {
  final GameTurn turn;

  const _GameTurnName({required this.turn});

  static const _ignoredTrailingLetters = {'ь', 'ъ', 'ы', '-', ' ', "'"};

  @override
  Widget build(BuildContext context) {
    final text = turn.locality?.matchedName ?? turn.input;

    if (turn.status != GameTurnStatus.accepted || text.isEmpty) {
      return Text(text);
    }

    final chars = text.characters.toList();
    final lastSignificantIndex = _findLastSignificantIndex(chars);

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 18),
        children: List.generate(chars.length, (index) {
          final isFirst = index == 0;
          final isLastSignificant = index == lastSignificantIndex;

          if (isFirst) {
            return TextSpan(
              text: chars[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            );
          }

          if (isLastSignificant) {
            return TextSpan(
              text: chars[index],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            );
          }

          return TextSpan(text: chars[index]);
        }),
      ),
    );
  }

  int _findLastSignificantIndex(List<String> chars) {
    for (var i = chars.length - 1; i >= 0; i--) {
      if (_ignoredTrailingLetters.contains(chars[i].toLowerCase())) {
        continue;
      }
      return i;
    }
    return chars.length - 1;
  }
}

class _GameTurnCard extends StatefulWidget {
  final GameTurn turn;
  final String rejectReasonText;

  const _GameTurnCard({
    super.key,
    required this.turn,
    required this.rejectReasonText,
  });

  @override
  State<_GameTurnCard> createState() => _GameTurnCardState();
}

class _GameTurnCardState extends State<_GameTurnCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final canExpand = widget.turn.locality != null;
    final isAi = widget.turn.actor == GameTurnActor.ai;

    return Card(
      child: InkWell(
        onTap: canExpand ? _toggleExpanded : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AiTurnLabel(isAi: isAi),
                        const SizedBox(height: 6),
                        _GameTurnName(turn: widget.turn),
                        if (widget.turn.status == GameTurnStatus.rejected)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(widget.rejectReasonText, style: const TextStyle(color: Colors.redAccent)),
                          ),
                        if (widget.turn.status == GameTurnStatus.surrendered)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Translator(
                              termin: AppGlossary.iSurrender,
                              builder: (text) => Text(text),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (canExpand)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: IconButton(
                        onPressed: _toggleExpanded,
                        icon: AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: const Icon(Icons.keyboard_arrow_down),
                        ),
                      ),
                    ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: _isExpanded && canExpand
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LocalityDetails(locality: widget.turn.locality!),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }
}
