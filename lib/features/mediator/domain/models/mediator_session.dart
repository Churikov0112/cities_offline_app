import '../utils/utils.dart';
import 'mediator_game_rules.dart';
import 'mediator_turn.dart';

class MediatorSession {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final MediatorGameRules rules;
  final List<MediatorTurn> turns;

  const MediatorSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.rules,
    required this.turns,
  });

  String get title => 'Игра ${createdAt.toLocal()}';

  String? get expectedStartLetter {
    for (var i = turns.length - 1; i >= 0; i--) {
      final turn = turns[i];
      if (turn.status == MediatorTurnStatus.accepted && turn.locality != null) {
        return lastSignificantLetter(turn.input);
      }
    }
    return null;
  }

  MediatorSession withTurn(MediatorTurn turn) {
    return copyWith(turns: [...turns, turn], updatedAt: DateTime.now());
  }

  MediatorSession copyWith({
    DateTime? updatedAt,
    MediatorGameRules? rules,
    List<MediatorTurn>? turns,
  }) {
    return MediatorSession(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rules: rules ?? this.rules,
      turns: turns ?? this.turns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'rules': rules.toJson(),
      'turns': turns.map((e) => e.toJson()).toList(),
    };
  }

  factory MediatorSession.fromJson(Map<String, dynamic> json) {
    final rawTurns = json['turns'] as List<dynamic>? ?? const [];
    return MediatorSession(
      id: json['id'] as String,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      rules: MediatorGameRules.fromJson(
        (json['rules'] as Map).cast<String, dynamic>(),
      ),
      turns: rawTurns
          .map((e) => MediatorTurn.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}
