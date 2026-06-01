import '../utils/utils.dart';
import 'ai_difficulty_config.dart';
import 'ai_fatigue_state.dart';
import 'ai_game_rules.dart';
import 'ai_turn.dart';

enum AiGameWinner { user, ai }

enum AiGameStatus { active, finished }

class AiGameSession {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AiGameRules rules;
  final AiDifficultyConfig currentDifficulty;
  final AiDifficultyConfig difficultyFloor;
  final AiFatigueState fatigue;
  final List<AiTurn> turns;
  final AiGameStatus status;
  final AiGameWinner? winner;
  final bool isAiThinking;

  const AiGameSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.rules,
    required this.currentDifficulty,
    required this.difficultyFloor,
    required this.fatigue,
    required this.turns,
    required this.status,
    required this.winner,
    required this.isAiThinking,
  });

  String get expectedStartLetter {
    for (var i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (turn.status == AiTurnStatus.accepted && turn.locality != null) {
        return lastSignificantLetter(turn.input) ?? '';
      }
    }
    return '';
  }

  AiGameSession copyWith({
    DateTime? updatedAt,
    AiGameRules? rules,
    AiDifficultyConfig? currentDifficulty,
    AiDifficultyConfig? difficultyFloor,
    AiFatigueState? fatigue,
    List<AiTurn>? turns,
    AiGameStatus? status,
    AiGameWinner? winner,
    bool? isAiThinking,
  }) {
    return AiGameSession(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rules: rules ?? this.rules,
      currentDifficulty: currentDifficulty ?? this.currentDifficulty,
      difficultyFloor: difficultyFloor ?? this.difficultyFloor,
      fatigue: fatigue ?? this.fatigue,
      turns: turns ?? this.turns,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      isAiThinking: isAiThinking ?? this.isAiThinking,
    );
  }

  AiGameSession withTurn(AiTurn turn) {
    return copyWith(turns: [...turns, turn], updatedAt: DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rules': rules.toJson(),
      'currentDifficulty': currentDifficulty.toJson(),
      'difficultyFloor': difficultyFloor.toJson(),
      'fatigue': fatigue.toJson(),
      'turns': turns.map((e) => e.toJson()).toList(),
      'status': status.name,
      'winner': winner?.name,
      'isAiThinking': isAiThinking,
    };
  }

  factory AiGameSession.fromJson(Map<String, dynamic> json) {
    final rawTurns = json['turns'] as List<dynamic>? ?? const [];
    return AiGameSession(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      rules: AiGameRules.fromJson(
        (json['rules'] as Map).cast<String, dynamic>(),
      ),
      currentDifficulty: AiDifficultyConfig.fromJson(
        (json['currentDifficulty'] as Map).cast<String, dynamic>(),
      ),
      difficultyFloor: AiDifficultyConfig.fromJson(
        (json['difficultyFloor'] as Map).cast<String, dynamic>(),
      ),
      fatigue: AiFatigueState.fromJson(
        (json['fatigue'] as Map).cast<String, dynamic>(),
      ),
      turns: rawTurns
          .map((e) => AiTurn.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      status: AiGameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AiGameStatus.active,
      ),
      winner: (json['winner'] as String?) == null
          ? null
          : AiGameWinner.values.firstWhere(
              (e) => e.name == json['winner'],
              orElse: () => AiGameWinner.user,
            ),
      isAiThinking: json['isAiThinking'] as bool? ?? false,
    );
  }
}
