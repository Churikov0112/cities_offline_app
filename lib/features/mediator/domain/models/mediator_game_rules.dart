class MediatorGameRules {
  final Set<String> allowedTypes;
  final bool allowHistoricalNames;
  final int minPopulation;

  const MediatorGameRules({
    required this.allowedTypes,
    required this.allowHistoricalNames,
    required this.minPopulation,
  });

  const MediatorGameRules.onlyCities()
    : allowedTypes = const {'city', 'town'},
      allowHistoricalNames = false,
      minPopulation = 0;

  bool isAllowedType(String type) => allowedTypes.contains(type.toLowerCase());

  Map<String, dynamic> toJson() {
    return {
      'allowedTypes': allowedTypes.toList(),
      'allowHistoricalNames': allowHistoricalNames,
      'minPopulation': minPopulation,
    };
  }

  factory MediatorGameRules.fromJson(Map<String, dynamic> json) {
    return MediatorGameRules(
      allowedTypes: ((json['allowedTypes'] as List<dynamic>?) ?? const ['city', 'town'])
          .map((e) => e.toString().toLowerCase())
          .toSet(),
      allowHistoricalNames: json['allowHistoricalNames'] as bool? ?? false,
      minPopulation: json['minPopulation'] as int? ?? 0,
    );
  }

  MediatorGameRules copyWith({
    Set<String>? allowedTypes,
    bool? allowHistoricalNames,
    int? minPopulation,
  }) {
    return MediatorGameRules(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowHistoricalNames: allowHistoricalNames ?? this.allowHistoricalNames,
      minPopulation: minPopulation ?? this.minPopulation,
    );
  }
}
