import 'package:cities_offline_app/features/ai_game/domain/models/ai_difficulty_config.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:flutter/material.dart';

class DifficultyPickerSheet extends StatefulWidget {
  final AiDifficultyConfig current;
  final AiDifficultyConfig customConfig;

  const DifficultyPickerSheet({
    required this.current,
    required this.customConfig,
    super.key,
  });

  @override
  State<DifficultyPickerSheet> createState() => _DifficultyPickerSheetState();
}

class _DifficultyPickerSheetState extends State<DifficultyPickerSheet> {
  late AiDifficultyPreset _preset;
  late int _candidatePoolSize;
  late double _mistakeChance;
  late int _baseThinkingDelayMs;
  late double _fatigueGrowthPerMove;
  late int _fatigueDelayPerPointMs;
  late double _fatigueMistakePerPoint;
  late double _surrenderChance;

  @override
  void initState() {
    super.initState();
    _preset = widget.current.preset;
    _candidatePoolSize = widget.customConfig.candidatePoolSize;
    _mistakeChance = widget.customConfig.mistakeChance;
    _baseThinkingDelayMs = widget.customConfig.baseThinkingDelayMs;
    _fatigueGrowthPerMove = widget.customConfig.fatigueGrowthPerMove;
    _fatigueDelayPerPointMs = widget.customConfig.fatigueDelayPerPointMs;
    _fatigueMistakePerPoint = widget.customConfig.fatigueMistakePerPoint;
    _surrenderChance = widget.customConfig.surrenderChance;
  }

  AiDifficultyConfig _buildConfig() {
    if (_preset != AiDifficultyPreset.custom) {
      return switch (_preset) {
        AiDifficultyPreset.easy => const AiDifficultyConfig.easy(),
        AiDifficultyPreset.medium => const AiDifficultyConfig.medium(),
        AiDifficultyPreset.hard => const AiDifficultyConfig.hard(),
        AiDifficultyPreset.custom => const AiDifficultyConfig.medium(),
      };
    }
    return AiDifficultyConfig.custom(
      candidatePoolSize: _candidatePoolSize,
      mistakeChance: _mistakeChance,
      baseThinkingDelayMs: _baseThinkingDelayMs,
      fatigueGrowthPerMove: _fatigueGrowthPerMove,
      fatigueDelayPerPointMs: _fatigueDelayPerPointMs,
      fatigueMistakePerPoint: _fatigueMistakePerPoint,
      surrenderChance: _surrenderChance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      color: Theme.of(context).canvasColor,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                AppGlossary.difficulty.translate(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final preset in AiDifficultyPreset.values)
                    ListTile(
                      leading: Radio<AiDifficultyPreset>(
                        value: preset,
                        groupValue: _preset,
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _preset = v);
                          }
                        },
                      ),
                      title: Text(translateDifficultyPreset(preset.name)),
                      onTap: () => setState(() => _preset = preset),
                    ),
                  if (_preset == AiDifficultyPreset.custom) ...[
                    const Divider(),
                    _NumberField(
                      label: 'Размер топ-пула',
                      initialValue: _candidatePoolSize.toString(),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) {
                          setState(() => _candidatePoolSize = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Шанс затупа',
                      initialValue: _mistakeChance.toString(),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() => _mistakeChance = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Базовая задержка (мс)',
                      initialValue: _baseThinkingDelayMs.toString(),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) {
                          setState(() => _baseThinkingDelayMs = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Рост усталости за ход',
                      initialValue: _fatigueGrowthPerMove.toString(),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() => _fatigueGrowthPerMove = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Задержка за усталость (мс)',
                      initialValue: _fatigueDelayPerPointMs.toString(),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) {
                          setState(() => _fatigueDelayPerPointMs = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Рост шанса затупа от усталости',
                      initialValue: _fatigueMistakePerPoint.toString(),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() => _fatigueMistakePerPoint = parsed);
                        }
                      },
                    ),
                    _NumberField(
                      label: 'Шанс сдачи',
                      initialValue: _surrenderChance.toString(),
                      onChanged: (v) {
                        final parsed = double.tryParse(v);
                        if (parsed != null) {
                          setState(() => _surrenderChance = parsed);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + mq.padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_buildConfig()),
                  child: Translator(
                    termin: AppGlossary.save,
                    builder: (text) => Text(text),
                  ),
                ),
              ),
            ),
          ],
        ),
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
