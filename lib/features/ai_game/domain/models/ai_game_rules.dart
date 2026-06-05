class AiGameRules {
  final Set<String> allowedTypes;
  final bool allowHistoricalNames;
  final int minPopulation;
  final String? preferredLanguage;

  const AiGameRules({
    required this.allowedTypes,
    required this.allowHistoricalNames,
    required this.minPopulation,
    this.preferredLanguage,
  });

  const AiGameRules.onlyCities()
    : allowedTypes = const {'city', 'town'},
      allowHistoricalNames = false,
      minPopulation = 0,
      preferredLanguage = null;

  bool isAllowedType(String type) => allowedTypes.contains(type.toLowerCase());

  Map<String, dynamic> toJson() {
    return {
      'allowedTypes': allowedTypes.toList(),
      'allowHistoricalNames': allowHistoricalNames,
      'minPopulation': minPopulation,
      'preferredLanguage': preferredLanguage,
    };
  }

  factory AiGameRules.fromJson(Map<String, dynamic> json) {
    return AiGameRules(
      allowedTypes:
          ((json['allowedTypes'] as List<dynamic>?) ?? const ['city', 'town'])
              .map((e) => e.toString().toLowerCase())
              .toSet(),
      allowHistoricalNames: json['allowHistoricalNames'] as bool? ?? false,
      minPopulation: json['minPopulation'] as int? ?? 0,
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  AiGameRules copyWith({
    Set<String>? allowedTypes,
    bool? allowHistoricalNames,
    int? minPopulation,
    String? preferredLanguage,
  }) {
    return AiGameRules(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowHistoricalNames: allowHistoricalNames ?? this.allowHistoricalNames,
      minPopulation: minPopulation ?? this.minPopulation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }
}
