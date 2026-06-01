class AiFatigueState {
  final int movesPlayed;
  final double fatigue;

  const AiFatigueState({
    required this.movesPlayed,
    required this.fatigue,
  });

  const AiFatigueState.initial() : movesPlayed = 0, fatigue = 0;

  AiFatigueState advance(double growth) {
    return AiFatigueState(
      movesPlayed: movesPlayed + 1,
      fatigue: fatigue + growth,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movesPlayed': movesPlayed,
      'fatigue': fatigue,
    };
  }

  factory AiFatigueState.fromJson(Map<String, dynamic> json) {
    return AiFatigueState(
      movesPlayed: json['movesPlayed'] as int? ?? 0,
      fatigue: (json['fatigue'] as num?)?.toDouble() ?? 0,
    );
  }
}
