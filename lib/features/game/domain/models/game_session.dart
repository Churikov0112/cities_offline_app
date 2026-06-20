import '../../../mediator/domain/utils/city_name_utils.dart';
import 'ai_state.dart';
import 'game_rules.dart';
import 'game_turn.dart';

enum GameWinner { user, ai }

enum GameStatus { active, finished }

enum OpponentType { none, ai }

class GameSession {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GameRules rules;
  final OpponentType opponent;
  final GameStatus status;
  final GameWinner? winner;
  final int score;
  final List<GameTurn> turns;
  final AiState? ai;
  final bool isVoiceEnabled;

  const GameSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.rules,
    required this.opponent,
    required this.status,
    this.winner,
    required this.score,
    required this.turns,
    this.ai,
    required this.isVoiceEnabled,
  });

  String get expectedStartLetter {
    for (var i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (turn.status == GameTurnStatus.accepted && turn.locality != null) {
        return lastSignificantLetter(turn.input) ?? '';
      }
    }
    return '';
  }

  String? get preferredUserLang {
    if (rules.preferredLanguage != null) {
      return rules.preferredLanguage;
    }

    for (var i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (turn.actor == GameTurnActor.user &&
          turn.status == GameTurnStatus.accepted) {
        return turn.locality?.matchedLang;
      }
    }
    return null;
  }

  Set<String> get acceptedLocalityIds =>
      turns
          .where(
            (t) => t.status == GameTurnStatus.accepted && t.locality != null,
          )
          .map((t) => t.locality!.id.toString())
          .toSet();

  int get computedScore =>
      turns
          .where(
            (t) => t.status == GameTurnStatus.accepted,
          )
          .length;

  GameSession copyWith({
    DateTime? updatedAt,
    GameRules? rules,
    OpponentType? opponent,
    GameStatus? status,
    GameWinner? winner,
    int? score,
    List<GameTurn>? turns,
    AiState? ai,
    bool? isVoiceEnabled,
  }) {
    return GameSession(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rules: rules ?? this.rules,
      opponent: opponent ?? this.opponent,
      status: status ?? this.status,
      winner: winner ?? this.winner,
      score: score ?? this.score,
      turns: turns ?? this.turns,
      ai: ai ?? this.ai,
      isVoiceEnabled: isVoiceEnabled ?? this.isVoiceEnabled,
    );
  }

  GameSession withTurn(GameTurn turn) {
    final newTurns = [...turns, turn];
    final newScore = turn.status == GameTurnStatus.accepted
        ? (turn.actor == GameTurnActor.user ? score + 1 : score)
        : score;
    return copyWith(
      turns: newTurns,
      score: newScore,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rules': rules.toJson(),
      'opponent': opponent.name,
      'status': status.name,
      'winner': winner?.name,
      'score': score,
      'turns': turns.map((e) => e.toJson()).toList(),
      'ai': ai?.toJson(),
      'isVoiceEnabled': isVoiceEnabled,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    final rawTurns = json['turns'] as List<dynamic>? ?? const [];
    final rawAi = json['ai'] as Map<String, dynamic>?;
    return GameSession(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      rules: GameRules.fromJson(
        (json['rules'] as Map).cast<String, dynamic>(),
      ),
      opponent: OpponentType.values.firstWhere(
        (e) => e.name == json['opponent'],
        orElse: () => OpponentType.none,
      ),
      status: GameStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GameStatus.active,
      ),
      winner: (json['winner'] as String?) == null
          ? null
          : GameWinner.values.firstWhere(
              (e) => e.name == json['winner'],
              orElse: () => GameWinner.user,
            ),
      score: json['score'] as int? ?? 0,
      turns: rawTurns
          .map((e) => GameTurn.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      ai: rawAi == null
          ? null
          : AiState.fromJson(rawAi),
      isVoiceEnabled: json['isVoiceEnabled'] as bool? ?? false,
    );
  }
}
