import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_difficulty_config.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_rules.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_state.dart';
import 'package:cities_offline_app/features/ai_game/presentation/bloc/ai_game_bloc.dart';
import 'package:cities_offline_app/features/ai_game/presentation/difficulty_picker_sheet.dart';
import 'package:cities_offline_app/features/ai_game/presentation/language_picker_sheet.dart';
import 'package:cities_offline_app/features/languages/presentation/bloc/languages_bloc.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:cities_offline_app/services/navigation/bottom_sheet_controller.dart';
import 'package:cities_offline_app/services/navigation/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AiRulesScreen extends StatefulWidget {
  final String? sessionId;

  const AiRulesScreen({super.key, this.sessionId});

  @override
  State<AiRulesScreen> createState() => _AiRulesScreenState();
}

class _AiRulesScreenState extends State<AiRulesScreen> {
  late AiGameRules _rules;
  late AiDifficultyConfig _difficulty;
  late AiDifficultyConfig _customDifficulty;
  final _populationController = TextEditingController();
  bool _waitingForNewSession = false;
  Set<String> _knownIds = <String>{};
  late final AiGameBloc _bloc;
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<AiGameBloc>();
    _knownIds = _bloc.state.sessions.keys.toSet();

    final existing = widget.sessionId == null ? null : _bloc.state.sessionById(widget.sessionId!);
    _rules = existing?.rules ?? const AiGameRules.onlyCities();
    _difficulty = existing?.currentDifficulty ?? const AiDifficultyConfig.medium();
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
    return BlocProvider.value(
      value: _bloc,
      child: Builder(
        builder: (context) {
          return BlocListener<AiGameBloc, AiGameState>(
            listenWhen: (previous, current) => _waitingForNewSession,
            listener: (context, state) {
              final newIds = state.sessions.keys.toSet().difference(_knownIds);
              if (newIds.isEmpty) {
                return;
              }

              final createdId = state.orderedSessionIds.firstWhere(
                (id) => newIds.contains(id),
                orElse: () => newIds.first,
              );
              _waitingForNewSession = false;
              context.pushReplacementNamed(
                RoutePaths.aiGame.name,
                pathParameters: {'sessionId': createdId},
              );
            },
            child: Scaffold(
              appBar: AppBar(
                title: Translator(
                  termin: AppGlossary.aiSettings,
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
                  ...['city', 'town', 'village', 'hamlet'].map(
                    (type) => CheckboxListTile(
                      value: _rules.allowedTypes.contains(type),
                      title: Text(translateCityType(type)),
                      onChanged: (v) {
                        setState(() {
                          final next = {..._rules.allowedTypes};
                          if (v == true) {
                            next.add(type);
                          } else {
                            next.remove(type);
                          }
                          _rules = _rules.copyWith(allowedTypes: next);
                        });
                      },
                    ),
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
                                .where(
                                  (l) => l.code == _selectedLanguage,
                                )
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      final minPopulation = int.tryParse(_populationController.text) ?? 0;
                      final finalRules = _rules.copyWith(
                        minPopulation: minPopulation,
                        preferredLanguage: _selectedLanguage,
                      );

                      if (widget.sessionId == null) {
                        _knownIds = _bloc.state.sessions.keys.toSet();
                        _waitingForNewSession = true;
                        _bloc.add(
                          AiSessionCreated(
                            rules: finalRules,
                            difficulty: _difficulty,
                          ),
                        );
                      } else {
                        _bloc.add(
                          AiRulesUpdated(
                            sessionId: widget.sessionId!,
                            rules: finalRules,
                          ),
                        );
                        _bloc.add(
                          AiDifficultyUpdated(
                            sessionId: widget.sessionId!,
                            difficulty: _difficulty,
                          ),
                        );
                        context.pop();
                      }
                    },
                    child: Translator(
                      termin: widget.sessionId == null ? AppGlossary.createGame : AppGlossary.save,
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
