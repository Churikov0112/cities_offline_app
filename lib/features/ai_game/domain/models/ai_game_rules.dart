class AiGameRules {
  final Set<String> allowedTypes;
  final bool allowHistoricalNames;
  final int minPopulation;
  final String? preferredLanguage;
  final Set<String> allowedCountryCodes;

  const AiGameRules({
    required this.allowedTypes,
    required this.allowHistoricalNames,
    required this.minPopulation,
    this.preferredLanguage,
    this.allowedCountryCodes = const {},
  });

  const AiGameRules.onlyCities()
    : allowedTypes = const {'city', 'town'},
      allowHistoricalNames = false,
      minPopulation = 0,
      preferredLanguage = null,
      allowedCountryCodes = const {};

  bool isAllowedType(String type) => allowedTypes.contains(type.toLowerCase());

  bool isAllowedCountry(String countryCode) =>
      allowedCountryCodes.isEmpty ||
      allowedCountryCodes.contains(countryCode.toLowerCase());

  Map<String, dynamic> toJson() {
    return {
      'allowedTypes': allowedTypes.toList(),
      'allowHistoricalNames': allowHistoricalNames,
      'minPopulation': minPopulation,
      'preferredLanguage': preferredLanguage,
      'allowedCountryCodes': allowedCountryCodes.toList(),
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
      allowedCountryCodes:
          ((json['allowedCountryCodes'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString().toLowerCase())
              .toSet(),
    );
  }

  AiGameRules copyWith({
    Set<String>? allowedTypes,
    bool? allowHistoricalNames,
    int? minPopulation,
    String? preferredLanguage,
    Set<String>? allowedCountryCodes,
  }) {
    return AiGameRules(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowHistoricalNames: allowHistoricalNames ?? this.allowHistoricalNames,
      minPopulation: minPopulation ?? this.minPopulation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      allowedCountryCodes: allowedCountryCodes ?? this.allowedCountryCodes,
    );
  }
}
