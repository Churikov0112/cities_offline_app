import '../../../ai_game/domain/models/ai_difficulty_config.dart';
import '../../../ai_game/domain/models/ai_fatigue_state.dart';

class AiState {
  final AiDifficultyConfig currentDifficulty;
  final AiDifficultyConfig difficultyFloor;
  final AiFatigueState fatigue;
  final bool isAiThinking;

  const AiState({
    required this.currentDifficulty,
    required this.difficultyFloor,
    required this.fatigue,
    required this.isAiThinking,
  });

  const AiState.initial()
    : currentDifficulty = const AiDifficultyConfig.medium(),
      difficultyFloor = const AiDifficultyConfig.medium(),
      fatigue = const AiFatigueState.initial(),
      isAiThinking = false;

  AiState copyWith({
    AiDifficultyConfig? currentDifficulty,
    AiDifficultyConfig? difficultyFloor,
    AiFatigueState? fatigue,
    bool? isAiThinking,
  }) {
    return AiState(
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      difficultyFloor: difficultyFloor ?? this.difficultyFloor,
      fatigue: fatigue ?? this.fatigue,
      isAiThinking: isAiThinking ?? this.isAiThinking,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentDifficulty': currentDifficulty.toJson(),
      'difficultyFloor': difficultyFloor.toJson(),
      'fatigue': fatigue.toJson(),
      'isAiThinking': isAiThinking,
    };
  }

  factory AiState.fromJson(Map<String, dynamic> json) {
    return AiState(
      currentDifficulty: AiDifficultyConfig.fromJson(
        (json['currentDifficulty'] as Map).cast<String, dynamic>(),
      ),
      difficultyFloor: AiDifficultyConfig.fromJson(
        (json['difficultyFloor'] as Map).cast<String, dynamic>(),
      ),
      fatigue: AiFatigueState.fromJson(
        (json['fatigue'] as Map).cast<String, dynamic>(),
      ),
      isAiThinking: json['isAiThinking'] as bool? ?? false,
    );
  }
}
