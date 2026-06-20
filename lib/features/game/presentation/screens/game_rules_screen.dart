import 'dart:math' as math;

import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_difficulty_config.dart';
import 'package:cities_offline_app/features/ai_game/presentation/country_picker_sheet.dart';
import 'package:cities_offline_app/features/ai_game/presentation/difficulty_picker_sheet.dart';
import 'package:cities_offline_app/features/ai_game/presentation/language_picker_sheet.dart';
import 'package:cities_offline_app/features/languages/presentation/bloc/languages_bloc.dart';
import 'package:cities_offline_app/features/villages/presentation/bloc/villages_cubit.dart';
import 'package:cities_offline_app/services/google_services/google_services_service.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/bottom_sheet_controller.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/game_rules.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/settlement_type.dart';
import '../bloc/game_bloc.dart';
import '../bloc/game_event.dart';

class GameRulesScreen extends StatefulWidget {
  final String? sessionId;

  const GameRulesScreen({super.key, this.sessionId});

  @override
  State<GameRulesScreen> createState() => _GameRulesScreenState();
}

class _GameRulesScreenState extends State<GameRulesScreen> {
  late GameRules _rules;
  late OpponentType _opponent;
  late bool _isVoiceEnabled;
  late AiDifficultyConfig _difficulty;
  late AiDifficultyConfig _customDifficulty;
  final _populationController = TextEditingController();
  bool _waitingForNewSession = false;
  String? _pendingSessionId;
  Set<String> _knownIds = <String>{};
  String? _selectedLanguage;
  bool? _googleServicesAvailable;

  @override
  void initState() {
    super.initState();
    final bloc = getIt<GameBloc>();
    _knownIds = bloc.state.sessions.keys.toSet();

    final existing = widget.sessionId == null
        ? null
        : bloc.state.sessionById(widget.sessionId!);
    _rules = existing?.rules ?? GameRules.onlyCities();
    _opponent = existing?.opponent ?? OpponentType.ai;
    _isVoiceEnabled = existing?.isVoiceEnabled ?? false;
    _difficulty = existing?.ai?.currentDifficulty ?? const AiDifficultyConfig.medium();
    _customDifficulty = _difficulty.preset == AiDifficultyPreset.custom
        ? _difficulty
        : const AiDifficultyConfig.custom(
            candidatePoolSize: 4,
            mistakeChance: 0.2,
            baseThinkingDelayMs: 900,
            fatigueDelayPerPointMs: 90,
            fatigueMistakePerPoint: 0.02,
            fatigueGrowthPerMove: 0.8,
            surrenderChance: 0.05,
          );
    _selectedLanguage = _rules.preferredLanguage;
    _populationController.text = _rules.minPopulation.toString();
    _checkGoogleServices();
  }

  Future<void> _checkGoogleServices() async {
    final available = await GoogleServicesService.hasGoogleServices();
    if (mounted) setState(() => _googleServicesAvailable = available);
  }

  @override
  void dispose() {
    _populationController.dispose();
    super.dispose();
  }

  void _showDifficultyPicker(BuildContext context) {
    BottomSheetController.showBottomSheet(
      context,
      (_) => DifficultyPickerSheet(
        current: _difficulty,
        customConfig: _customDifficulty,
      ),
      expand: true,
    ).then((result) {
      if (result is AiDifficultyConfig) {
        setState(() {
          _difficulty = result;
          if (result.preset == AiDifficultyPreset.custom) {
            _customDifficulty = result;
          }
        });
      }
    });
  }

  void _showCountryPicker(BuildContext context) {
    BottomSheetController.showBottomSheet(
      context,
      (_) => CountryPickerSheet(
        selectedCodes: _rules.allowedCountryCodes,
        onChanged: (codes) {
          setState(() {
            _rules = _rules.copyWith(allowedCountryCodes: codes);
          });
        },
      ),
      expand: true,
    );
  }

  void _showLanguagePicker(BuildContext context, LanguagesState langState) {
    BottomSheetController.showBottomSheet(
      context,
      (sheetContext) => LanguagePickerSheet(
        languages: langState.languages,
        selectedCode: _selectedLanguage,
        grouped: false,
        onSelected: (code) {
          setState(() {
            _selectedLanguage = code;
          });
          Navigator.of(sheetContext).pop();
        },
      ),
      expand: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = getIt<GameBloc>();

    return BlocProvider.value(
      value: bloc,
      child: Builder(
        builder: (context) {
          return BlocListener<GameBloc, GameState>(
            listenWhen: (previous, current) => _waitingForNewSession,
            listener: (context, state) {
              final id = _pendingSessionId;
              if (id == null) return;
              if (!state.sessions.containsKey(id)) return;
              _pendingSessionId = null;
              _waitingForNewSession = false;
              context.pushReplacementNamed(
                RoutePaths.gameSession.name,
                pathParameters: {'sessionId': id},
              );
            },
            child: Scaffold(
              appBar: AppBar(
                title: Translator(
                  termin: AppGlossary.gameSettings,
                  builder: (text) => Text(text),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Translator(
                    termin: AppGlossary.settlementTypes,
                    builder: (text) => Text(text),
                  ),
                  BlocBuilder<VillagesCubit, VillagesState>(
                    builder: (context, villagesState) {
                      return SwitchListTile(
                        value: _rules.allowedTypes.contains(SettlementType.village),
                        title: Translator(
                          termin: AppGlossary.withVillages,
                          builder: (text) => Text(text),
                        ),
                        subtitle: villagesState.isAvailable
                            ? null
                            : Text(
                                AppGlossary.downloadVillagesDbHint.translate(),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                        onChanged: villagesState.isAvailable ? (v) {
                          setState(() {
                            _rules = _rules.copyWith(
                              allowedTypes: v
                                  ? SettlementType.values.toSet()
                                  : {SettlementType.city, SettlementType.town},
                            );
                          });
                        } : null,
                      );
                    },
                  ),
                  ListTile(
                    title: Text(AppGlossary.countries.translate()),
                    subtitle: Text(_rules.allowedCountryCodes.isEmpty
                        ? AppGlossary.all.translate()
                        : '${_rules.allowedCountryCodes.length} ${AppGlossary.countries.translate().toLowerCase()}'),
                    trailing: const Icon(Icons.keyboard_arrow_down),
                    onTap: () => _showCountryPicker(context),
                  ),
                  SwitchListTile(
                    value: _rules.allowHistoricalNames,
                    title: Translator(
                      termin: AppGlossary.allowHistoricalNames,
                      builder: (text) => Text(text),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _rules = _rules.copyWith(allowHistoricalNames: v);
                      });
                    },
                  ),
                  TextField(
                    controller: _populationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppGlossary.minPopulation.translate(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Translator(
                    termin: AppGlossary.gameLanguage,
                    builder: (text) => Text(text),
                  ),
                  BlocBuilder<LanguagesBloc, LanguagesState>(
                    bloc: getIt(),
                    builder: (context, langState) {
                      if (langState.status == LanguagesStatus.loading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final selectedLang = _selectedLanguage == null
                          ? null
                          : langState.languages
                                .where((l) => l.code == _selectedLanguage)
                                .firstOrNull;
                      final label = selectedLang != null
                          ? '${selectedLang.nativeName} (${selectedLang.code})'
                          : AppGlossary.auto.translate();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showLanguagePicker(context, langState),
                          borderRadius: BorderRadius.circular(4),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(label),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _opponent == OpponentType.ai,
                    title: const Text('AI opponent'),
                    subtitle: const Text('Enable AI to play against you'),
                    onChanged: (v) {
                      setState(() {
                        _opponent = v ? OpponentType.ai : OpponentType.none;
                      });
                    },
                  ),
                  if (_opponent == OpponentType.ai) ...[
                    const SizedBox(height: 12),
                    Translator(
                      termin: AppGlossary.difficulty,
                      builder: (text) => Text(text),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      title: Text(translateDifficultyPreset(_difficulty.preset.name)),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      onTap: () => _showDifficultyPicker(context),
                    ),
                    const SizedBox(height: 8),
                    Translator(
                      termin: AppGlossary.difficultyChangesInstant,
                      builder: (text) => Text(text),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _isVoiceEnabled,
                    title: const Text('Voice input'),
                    subtitle: _googleServicesAvailable == false
                        ? Text(
                            AppGlossary.voiceGameNotAvailable.translate(),
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        : const Text('Use speech recognition & text-to-speech'),
                    onChanged: _googleServicesAvailable == true ? (v) {
                      setState(() {
                        _isVoiceEnabled = v;
                      });
                    } : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final minPopulation = int.tryParse(_populationController.text) ?? 0;
                      final finalRules = _rules.copyWith(
                        minPopulation: minPopulation,
                        preferredLanguage: _selectedLanguage,
                      );

                      if (widget.sessionId == null) {
                        final sessionId = 'game_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(99999)}';
                        _pendingSessionId = sessionId;
                        _knownIds = bloc.state.sessions.keys.toSet();
                        _waitingForNewSession = true;
                        bloc.add(
                          GameSessionCreated(
                            id: sessionId,
                            rules: finalRules,
                            opponent: _opponent,
                            difficulty: _opponent == OpponentType.ai
                                ? _difficulty
                                : null,
                            isVoiceEnabled: _isVoiceEnabled,
                          ),
                        );
                      } else {
                        bloc.add(
                          GameRulesUpdated(
                            sessionId: widget.sessionId!,
                            rules: finalRules,
                          ),
                        );
                        bloc.add(
                          GameOpponentUpdated(
                            sessionId: widget.sessionId!,
                            opponent: _opponent,
                            difficulty: _opponent == OpponentType.ai
                                ? _difficulty
                                : null,
                          ),
                        );
                        bloc.add(
                          GameVoiceToggled(
                            sessionId: widget.sessionId!,
                            isVoiceEnabled: _isVoiceEnabled,
                          ),
                        );
                        if (_opponent == OpponentType.ai) {
                          bloc.add(
                            GameDifficultyUpdated(
                              sessionId: widget.sessionId!,
                              difficulty: _difficulty,
                            ),
                          );
                        }
                        context.pop();
                      }
                    },
                    child: Translator(
                      termin: widget.sessionId == null
                          ? AppGlossary.createGame
                          : AppGlossary.save,
                      builder: (text) => Text(text),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
