import 'package:cities_offline_app/di/di.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_difficulty_config.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_rules.dart';
import 'package:cities_offline_app/features/ai_game/domain/models/ai_game_state.dart';
import 'package:cities_offline_app/features/ai_game/presentation/bloc/ai_game_bloc.dart';
import 'package:cities_offline_app/features/languages/presentation/bloc/languages_bloc.dart';
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
              appBar: AppBar(title: const Text('Настройки ИИ')),
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  const Text('Типы поселений'),
                  ...['city', 'town', 'village', 'hamlet'].map(
                    (type) => CheckboxListTile(
                      value: _rules.allowedTypes.contains(type),
                      title: Text(type),
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
                    title: const Text('Засчитывать старые названия'),
                    onChanged: (v) {
                      setState(() {
                        _rules = _rules.copyWith(allowHistoricalNames: v);
                      });
                    },
                  ),
                  TextField(
                    controller: _populationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Минимальная численность населения',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Язык игры'),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String?>(
                          value: _selectedLanguage,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Авто (по вводу)'),
                            ),
                            ...langState.languages.map(
                              (lang) => DropdownMenuItem(
                                value: lang.code,
                                child: Text('${lang.nativeName} (${lang.code})'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedLanguage = value;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text('Сложность ИИ'),
                  DropdownButtonFormField<AiDifficultyPreset>(
                    initialValue: _difficulty.preset,
                    items: AiDifficultyPreset.values
                        .map(
                          (preset) => DropdownMenuItem(
                            value: preset,
                            child: Text(preset.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        switch (value) {
                          case AiDifficultyPreset.easy:
                            _difficulty = const AiDifficultyConfig.easy();
                            break;
                          case AiDifficultyPreset.medium:
                            _difficulty = const AiDifficultyConfig.medium();
                            break;
                          case AiDifficultyPreset.hard:
                            _difficulty = const AiDifficultyConfig.hard();
                            break;
                          case AiDifficultyPreset.custom:
                            _difficulty = _customDifficulty;
                            break;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Изменения сложности применяются сразу к текущей игре.',
                  ),
                  if (_difficulty.preset == AiDifficultyPreset.custom) ...[
                    const SizedBox(height: 16),
                    _NumberField(
                      label: 'Размер топ-пула',
                      initialValue: _difficulty.candidatePoolSize.toString(),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            candidatePoolSize: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Шанс затупа',
                      initialValue: _difficulty.mistakeChance.toString(),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            mistakeChance: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Базовая задержка (мс)',
                      initialValue: _difficulty.baseThinkingDelayMs.toString(),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            baseThinkingDelayMs: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Рост усталости за ход',
                      initialValue: _difficulty.fatigueGrowthPerMove.toString(),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            fatigueGrowthPerMove: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Задержка за усталость (мс)',
                      initialValue: _difficulty.fatigueDelayPerPointMs.toString(),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            fatigueDelayPerPointMs: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Рост шанса затупа от усталости',
                      initialValue: _difficulty.fatigueMistakePerPoint.toString(),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            fatigueMistakePerPoint: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                    _NumberField(
                      label: 'Шанс сдачи',
                      initialValue: _difficulty.surrenderChance.toString(),
                      onChanged: (value) {
                        final parsed = double.tryParse(value);
                        if (parsed == null) {
                          return;
                        }
                        setState(() {
                          _difficulty = _difficulty.copyWith(
                            surrenderChance: parsed,
                          );
                          _customDifficulty = _difficulty;
                        });
                      },
                    ),
                  ],
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
                    child: Text(
                      widget.sessionId == null ? 'Создать игру' : 'Сохранить',
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

class _NumberField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: initialValue,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label),
        onChanged: onChanged,
      ),
    );
  }
}
