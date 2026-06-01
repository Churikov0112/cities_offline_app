enum AiDifficultyPreset { easy, medium, hard, custom }

class AiDifficultyConfig {
  final AiDifficultyPreset preset;
  final int candidatePoolSize;
  final double mistakeChance;
  final int baseThinkingDelayMs;
  final int fatigueDelayPerPointMs;
  final double fatigueMistakePerPoint;
  final double fatigueGrowthPerMove;
  final double surrenderChance;

  const AiDifficultyConfig({
    required this.preset,
    required this.candidatePoolSize,
    required this.mistakeChance,
    required this.baseThinkingDelayMs,
    required this.fatigueDelayPerPointMs,
    required this.fatigueMistakePerPoint,
    required this.fatigueGrowthPerMove,
    required this.surrenderChance,
  });

  const AiDifficultyConfig.easy()
    : this(
        preset: AiDifficultyPreset.easy,
        candidatePoolSize: 8,
        mistakeChance: 0.35,
        baseThinkingDelayMs: 1200,
        fatigueDelayPerPointMs: 120,
        fatigueMistakePerPoint: 0.03,
        fatigueGrowthPerMove: 1.0,
        surrenderChance: 0.10,
      );

  const AiDifficultyConfig.medium()
    : this(
        preset: AiDifficultyPreset.medium,
        candidatePoolSize: 5,
        mistakeChance: 0.18,
        baseThinkingDelayMs: 900,
        fatigueDelayPerPointMs: 90,
        fatigueMistakePerPoint: 0.02,
        fatigueGrowthPerMove: 0.85,
        surrenderChance: 0.05,
      );

  const AiDifficultyConfig.hard()
    : this(
        preset: AiDifficultyPreset.hard,
        candidatePoolSize: 2,
        mistakeChance: 0.07,
        baseThinkingDelayMs: 650,
        fatigueDelayPerPointMs: 70,
        fatigueMistakePerPoint: 0.015,
        fatigueGrowthPerMove: 0.65,
        surrenderChance: 0.01,
      );

  const AiDifficultyConfig.custom({
    required int candidatePoolSize,
    required double mistakeChance,
    required int baseThinkingDelayMs,
    required int fatigueDelayPerPointMs,
    required double fatigueMistakePerPoint,
    required double fatigueGrowthPerMove,
    required double surrenderChance,
  }) : this(
         preset: AiDifficultyPreset.custom,
         candidatePoolSize: candidatePoolSize,
         mistakeChance: mistakeChance,
         baseThinkingDelayMs: baseThinkingDelayMs,
         fatigueDelayPerPointMs: fatigueDelayPerPointMs,
         fatigueMistakePerPoint: fatigueMistakePerPoint,
         fatigueGrowthPerMove: fatigueGrowthPerMove,
         surrenderChance: surrenderChance,
       );

  int get difficultyRank {
    final mistakeComponent = ((1 - mistakeChance) * 100).round() * 10;
    final poolComponent = candidatePoolSize * 100;
    final delayComponent = ((1000 - baseThinkingDelayMs).clamp(0, 1000)) ~/ 10;
    return poolComponent + mistakeComponent + delayComponent;
  }

  AiDifficultyConfig copyWith({
    AiDifficultyPreset? preset,
    int? candidatePoolSize,
    double? mistakeChance,
    int? baseThinkingDelayMs,
    int? fatigueDelayPerPointMs,
    double? fatigueMistakePerPoint,
    double? fatigueGrowthPerMove,
    double? surrenderChance,
  }) {
    return AiDifficultyConfig(
      preset: preset ?? this.preset,
      candidatePoolSize: candidatePoolSize ?? this.candidatePoolSize,
      mistakeChance: mistakeChance ?? this.mistakeChance,
      baseThinkingDelayMs: baseThinkingDelayMs ?? this.baseThinkingDelayMs,
      fatigueDelayPerPointMs:
          fatigueDelayPerPointMs ?? this.fatigueDelayPerPointMs,
      fatigueMistakePerPoint:
          fatigueMistakePerPoint ?? this.fatigueMistakePerPoint,
      fatigueGrowthPerMove: fatigueGrowthPerMove ?? this.fatigueGrowthPerMove,
      surrenderChance: surrenderChance ?? this.surrenderChance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preset': preset.name,
      'candidatePoolSize': candidatePoolSize,
      'mistakeChance': mistakeChance,
      'baseThinkingDelayMs': baseThinkingDelayMs,
      'fatigueDelayPerPointMs': fatigueDelayPerPointMs,
      'fatigueMistakePerPoint': fatigueMistakePerPoint,
      'fatigueGrowthPerMove': fatigueGrowthPerMove,
      'surrenderChance': surrenderChance,
    };
  }

  factory AiDifficultyConfig.fromJson(Map<String, dynamic> json) {
    final preset = AiDifficultyPreset.values.firstWhere(
      (e) => e.name == json['preset'],
      orElse: () => AiDifficultyPreset.medium,
    );
    if (preset == AiDifficultyPreset.easy) {
      return const AiDifficultyConfig.easy();
    }
    if (preset == AiDifficultyPreset.hard) {
      return const AiDifficultyConfig.hard();
    }
    if (preset == AiDifficultyPreset.custom) {
      return AiDifficultyConfig.custom(
        candidatePoolSize: json['candidatePoolSize'] as int? ?? 5,
        mistakeChance: (json['mistakeChance'] as num?)?.toDouble() ?? 0.18,
        baseThinkingDelayMs: json['baseThinkingDelayMs'] as int? ?? 900,
        fatigueDelayPerPointMs: json['fatigueDelayPerPointMs'] as int? ?? 90,
        fatigueMistakePerPoint:
            (json['fatigueMistakePerPoint'] as num?)?.toDouble() ?? 0.02,
        fatigueGrowthPerMove:
            (json['fatigueGrowthPerMove'] as num?)?.toDouble() ?? 0.85,
        surrenderChance: (json['surrenderChance'] as num?)?.toDouble() ?? 0.05,
      );
    }
    return const AiDifficultyConfig.medium();
  }
}
