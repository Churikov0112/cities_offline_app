import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui_kit/widgets/ai_turn_card/ai_turn_card.dart';
import '../../../../di/di.dart';
import '../../../../services/google_services/google_services_service.dart';
import '../../../../services/localization/translator.dart';
import '../../../ai_game/domain/models/ai_difficulty_config.dart';
import '../../../ai_game/domain/models/ai_game_rules.dart';
import '../../../ai_game/domain/models/ai_game_session.dart';
import '../../../ai_game/domain/models/ai_game_state.dart';
import '../../../ai_game/domain/models/ai_turn.dart';
import '../../../ai_game/domain/services/ai_move_service.dart';
import '../../../ai_game/presentation/bloc/ai_game_bloc.dart';
import '../../../mediator/domain/models/locality.dart';
import '../../../mediator/domain/repos/cities_repository.dart';
import '../../services/city_info_service.dart';
import '../../services/command_parser.dart';
import '../../services/intent_lexemes.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../cubit/voice_game_cubit.dart';
import '../cubit/voice_game_state.dart';
import '../widgets/mic_button.dart';

class VoiceGameScreen extends StatefulWidget {
  final String? sessionId;

  const VoiceGameScreen({super.key, this.sessionId});

  @override
  State<VoiceGameScreen> createState() => _VoiceGameScreenState();
}

class _VoiceGameScreenState extends State<VoiceGameScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final TextEditingController _textController = TextEditingController();
  late final CityInfoService _cityInfo;
  late final VoiceGameCubit _cubit;
  late final AiGameBloc _gameBloc;
  late final AiMoveService _aiMove;
  late final CitiesRepository _repo;
  late CommandParser _parser;

  String? _sessionId;
  bool _isPlaying = true;
  bool _skipNextPrompt = false;
  String? _lastAiCityName;
  bool _processingInput = false;

  @override
  void initState() {
    super.initState();
    _cubit = VoiceGameCubit();
    _gameBloc = getIt<AiGameBloc>();
    _aiMove = getIt<AiMoveService>();
    _repo = getIt<CitiesRepository>();
    _cityInfo = CityInfoService();
    _initServices();
  }

  Future<void> _initServices() async {
    if (!await GoogleServicesService.hasGoogleServices()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppGlossary.voiceGameNotAvailable.translate()),
          ),
        );
        context.pop();
      }
      return;
    }

    await _speech.initialize();
    await _tts.initialize();

    final uiLang = getIt<LanguageBloc>().state.language;

    final locale = await _speech.currentLocale;
    final detected = CityInfoService.languageFromLocale(locale);
    final voiceLang = detected ?? uiLang;

    _parser = CommandParser(repo: _repo, uiLanguage: voiceLang);

    if (detected != null) {
      _cityInfo.setLanguage(detected);
      await _tts.setLanguage(CityInfoService.localeForTts(locale));
    }

    if (widget.sessionId != null) {
      _sessionId = widget.sessionId;
      unawaited(_startGame());
    } else {
      unawaited(_createAndStart());
    }
  }

  Future<void> _createAndStart() async {
    final prevIds = List<String>.from(_gameBloc.state.orderedSessionIds);
    _gameBloc.add(
      AiSessionCreated(
        rules: const AiGameRules.onlyCities(),
        difficulty: const AiDifficultyConfig.medium(),
      ),
    );

    await _gameBloc.stream.firstWhere(
      (state) => state.orderedSessionIds.length > prevIds.length,
    );

    final newId = _gameBloc.state.orderedSessionIds.firstWhere((id) => !prevIds.contains(id));
    _sessionId = newId;
    unawaited(_startGame());
  }

  Future<void> _startGame() async {
    _cubit.setStatusText('');
    await _tts.speak(_cityInfo.welcomingText());

    while (_isPlaying) {
      await _processTurn();
    }
  }

  Future<void> _processTurn() async {
    if (_processingInput) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    final session = _currentSession();
    if (session == null || session.status == AiGameStatus.finished) {
      await _handleGameOver(session);
      return;
    }

    // Handle pending turn results (from text input)
    if (_hasPendingResult(session)) {
      await _handleTurnResult(session);
      return;
    }

    final letter = session.expectedStartLetter;

    _cubit.setPhase(VoicePhase.speaking);
    _cubit.setStatusText(
      (letter.isEmpty ? AppGlossary.voiceAnyCity : AppGlossary.voiceTurnPrompt)
          .translate()
          .replaceAll('{letter}', letter),
    );
    if (_skipNextPrompt) {
      _skipNextPrompt = false;
    } else {
      await _tts.speak(_cityInfo.turnPrompt(letter));
      if (!mounted) return;
    }

    _cubit.setPhase(VoicePhase.listening);
    _cubit.setStatusText(AppGlossary.voiceListening.translate());
    final text = await _speech.listen(
      timeout: SpeechService.timeout,
      pause: SpeechService.pause,
    );
    if (!mounted || _processingInput) return;

    if (text == null || text.isEmpty) {
      await _tts.speak(_cityInfo.quietText());
      return;
    }

    _cubit.setPhase(VoicePhase.processing);
    _cubit.setStatusText(text);

    final cmd = await _parser.parse(text);
    if (!mounted) return;

    switch (cmd.intent) {
      case VoiceIntent.cityName:
        await _handleCityName(cmd.rawText);
      case VoiceIntent.hint:
        await _handleHint();
      case VoiceIntent.population:
        await _handleInfo(cmd.rawText, InfoType.population);
      case VoiceIntent.location:
        await _handleInfo(cmd.rawText, InfoType.location);
      case VoiceIntent.type:
        await _handleInfo(cmd.rawText, InfoType.type);
      case VoiceIntent.repeat:
        await _tts.speak(_cityInfo.repeatTurnText(_currentSession()?.expectedStartLetter ?? '?'));
      case VoiceIntent.score:
        final accepted = _acceptedCount();
        _cubit.setStatusText(AppGlossary.voiceScore.translate().replaceAll('{count}', accepted.toString()));
        await _tts.speak(_cityInfo.scoreText(accepted));
      case VoiceIntent.surrender:
      case VoiceIntent.unknown:
        final l = _currentSession()?.expectedStartLetter ?? '?';
        await _tts.speak(_cityInfo.notUnderstoodText(l));
        _cubit.setStatusText(AppGlossary.voiceNotUnderstood.translate().replaceAll('{letter}', l));
    }
  }

  bool _hasPendingResult(AiGameSession session) {
    if (session.turns.isEmpty) return false;
    final last = session.turns.last;
    return last.actor == AiTurnActor.user && last.status != AiTurnStatus.accepted;
  }

  Future<void> _handleTurnResult(AiGameSession session) async {
    final lastTurn = session.turns.last;

    if (lastTurn.status == AiTurnStatus.rejected) {
      final reason = _cityInfo.rejectReasonText(lastTurn);
      _cubit.setStatusText(reason);
      await _tts.speak(_cityInfo.cityRejectedText(reason));
      return;
    }

    if (lastTurn.status == AiTurnStatus.surrendered) {
      await _handleGameOver(session);
    }
  }

  Future<void> _handleCityName(String text) async {
    _processingInput = true;

    final session = _currentSession();
    if (session == null) {
      _processingInput = false;
      return;
    }

    final prevTurns = session.turns.length;

    _gameBloc.add(AiCitySubmitted(sessionId: _sessionId!, cityName: text));

    await _gameBloc.stream.firstWhere((state) {
      final s = state.sessionById(_sessionId!);
      return s != null &&
          s.turns.length > prevTurns &&
          !s.isAiThinking &&
          (s.turns.last.status != AiTurnStatus.accepted || s.turns.last.actor != AiTurnActor.user);
    });
    if (!mounted) {
      _processingInput = false;
      return;
    }

    final updated = _currentSession();
    if (updated == null) {
      _processingInput = false;
      return;
    }

    final lastTurn = updated.turns.last;

    if (lastTurn.status == AiTurnStatus.rejected) {
      final reason = _cityInfo.rejectReasonText(lastTurn);
      _cubit.setStatusText(reason);
      await _tts.speak(_cityInfo.cityRejectedText(reason));
      _processingInput = false;
      return;
    }

    if (lastTurn.actor == AiTurnActor.ai && lastTurn.locality != null) {
      final cityName = lastTurn.locality!.matchedName;
      _lastAiCityName = cityName;
      final nextLetter = lastTurn.expectedStartLetter ?? updated.expectedStartLetter;
      _cubit.setStatusText(AppGlossary.voiceAiResponded.translate().replaceAll('{city}', cityName).replaceAll('{letter}', nextLetter));
      _skipNextPrompt = true;
      await _tts.speak(_cityInfo.aiRespondedText(cityName, nextLetter));

      if (updated.status == AiGameStatus.finished) {
        await _handleGameOver(updated);
      }
      _processingInput = false;
      return;
    }

    if (lastTurn.status == AiTurnStatus.surrendered) {
      await _handleGameOver(updated);
    }

    _processingInput = false;
  }

  Future<void> _handleHint() async {
    final session = _currentSession();
    if (session == null) return;

    final hint = await _aiMove.pickHint(session);
    if (!mounted) return;
    if (hint != null) {
      _cubit.setStatusText(AppGlossary.voiceHint.translate().replaceAll('{city}', hint.matchedName));
      await _tts.speak(_cityInfo.hintText(hint.matchedName));
    } else {
      _cubit.setStatusText(AppGlossary.voiceNoHints.translate());
      await _tts.speak(_cityInfo.noHintsText());
    }
  }

  Future<void> _handleInfo(String text, InfoType type) async {
    final cityName = await _parser.extractCityName(text);
    if (!mounted) return;
    Locality? city;

    if (cityName != null) {
      city = await _repo.findLocalityByName(cityName);
      if (!mounted) return;
    }

    if (city == null && _lastAiCityName != null) {
      city = await _repo.findLocalityByName(_lastAiCityName!);
      if (!mounted) return;
    }

    if (city == null) {
      final msg = _cityInfo.couldNotIdentifyText();
      await _tts.speak(msg);
      return;
    }

    final msg = switch (type) {
      InfoType.population => _cityInfo.populationText(city),
      InfoType.location => _cityInfo.locationText(city),
      InfoType.type => _cityInfo.typeText(city),
    };
    _cubit.setStatusText(msg);
    await _tts.speak(msg);
  }

  void _onTextSubmitted() {
    if (_processingInput) return;
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    _processingInput = true;
    _speech.stop().catchError((_) {});
    _gameBloc.add(AiCitySubmitted(sessionId: _sessionId!, cityName: text));
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
      _isPlaying = false;
      _tts.stop();
      _speech.stop();
      context.pop();
    }
  }

  Future<void> _handleGameOver(AiGameSession? session) async {
    if (!mounted) return;
    if (session == null) {
      _cubit.setStatusText(AppGlossary.voiceSurrenderAccepted.translate());
      return;
    }

    final userWon = session.winner == AiGameWinner.user;
    _cubit.setStatusText((userWon ? AppGlossary.voiceYouWon : AppGlossary.voiceAiWon).translate());
    _cubit.setPhase(VoicePhase.gameOver);
    await _tts.speak(userWon ? _cityInfo.youWonText() : _cityInfo.aiWonText());
    _isPlaying = false;
  }

  AiGameSession? _currentSession() => _sessionId != null ? _gameBloc.state.sessionById(_sessionId!) : null;

  int _acceptedCount() {
    final s = _currentSession();
    if (s == null) return 0;
    return s.turns
        .where((t) => t.status == AiTurnStatus.accepted && t.actor == AiTurnActor.user)
        .length;
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.cancel();
    _tts.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _showExitConfirmation();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(AppGlossary.voiceTitle.translate()),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _showExitConfirmation(),
              ),
            ],
          ),
          body: BlocProvider.value(
            value: _gameBloc,
            child: SafeArea(
              child: Column(
                children: [
                  BlocBuilder<VoiceGameCubit, VoiceGameState>(
                    builder: (context, state) {
                      if (state.statusText.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          state.statusText,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: BlocSelector<AiGameBloc, AiGameState, AiGameSession?>(
                      selector: (state) => state.sessionById(_sessionId ?? ''),
                      builder: (context, session) {
                        if (session == null || session.turns.isEmpty) {
                          return Center(
                            child: Text(AppGlossary.voiceSayOrTypeCity.translate()),
                          );
                        }

                        return ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          itemCount: session.turns.length + (session.isAiThinking ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (session.isAiThinking && index == 0) {
                              return const AiThinkingCard();
                            }

                            final adjustedIndex = session.isAiThinking ? index - 1 : index;
                            final turn = session.turns[session.turns.length - 1 - adjustedIndex];
                            return AiTurnCard(
                              key: ValueKey(
                                '${turn.actor.name}-${turn.input}-$index-${turn.locality?.id ?? "none"}-$_sessionId',
                              ),
                              turn: turn,
                              rejectReasonText: _cityInfo.rejectReasonText(turn),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        BlocBuilder<VoiceGameCubit, VoiceGameState>(
                          builder: (context, state) {
                            return MicButton(
                              isListening: state.phase == VoicePhase.listening,
                              isProcessing: state.phase == VoicePhase.processing || state.phase == VoicePhase.thinking,
                              compact: true,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: BlocSelector<AiGameBloc, AiGameState, AiGameSession?>(
                            selector: (state) => state.sessionById(_sessionId ?? ''),
                            builder: (context, session) {
                              final disabled = session == null ||
                                  session.isAiThinking ||
                                  session.status != AiGameStatus.active;
                              return TextField(
                                controller: _textController,
                                textInputAction: TextInputAction.send,
                                onSubmitted: disabled ? null : (_) => _onTextSubmitted(),
                                enabled: !disabled,
                                decoration: InputDecoration(
                                  hintText: AppGlossary.enterCity.translate(),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        BlocSelector<AiGameBloc, AiGameState, AiGameSession?>(
                          selector: (state) => state.sessionById(_sessionId ?? ''),
                          builder: (context, session) {
                            final canSubmit = session != null &&
                                !session.isAiThinking &&
                                session.status == AiGameStatus.active &&
                                _textController.text.trim().isNotEmpty;
                            return IconButton.filled(
                              onPressed: canSubmit ? _onTextSubmitted : null,
                              icon: const Icon(Icons.send),
                            );
                          },
                        ),
                        const SizedBox(width: 4),
                        BlocSelector<AiGameBloc, AiGameState, AiGameSession?>(
                          selector: (state) => state.sessionById(_sessionId ?? ''),
                          builder: (context, session) {
                            final enabled = session != null &&
                                !session.isAiThinking &&
                                session.status == AiGameStatus.active;
                            return IconButton(
                              onPressed: enabled ? _handleHint : null,
                              icon: const Icon(Icons.help_outline),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum InfoType { population, location, type }
