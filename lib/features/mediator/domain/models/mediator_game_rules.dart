class MediatorGameRules {
  final Set<String> allowedTypes;
  final bool allowHistoricalNames;
  final int minPopulation;
  final Set<String> allowedCountryCodes;

  const MediatorGameRules({
    required this.allowedTypes,
    required this.allowHistoricalNames,
    required this.minPopulation,
    this.allowedCountryCodes = const {},
  });

  const MediatorGameRules.onlyCities()
    : allowedTypes = const {'city', 'town'},
      allowHistoricalNames = false,
      minPopulation = 0,
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
      'allowedCountryCodes': allowedCountryCodes.toList(),
    };
  }

  factory MediatorGameRules.fromJson(Map<String, dynamic> json) {
    return MediatorGameRules(
      allowedTypes: ((json['allowedTypes'] as List<dynamic>?) ?? const ['city', 'town'])
          .map((e) => e.toString().toLowerCase())
          .toSet(),
      allowHistoricalNames: json['allowHistoricalNames'] as bool? ?? false,
      minPopulation: json['minPopulation'] as int? ?? 0,
      allowedCountryCodes:
          ((json['allowedCountryCodes'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString().toLowerCase())
              .toSet(),
    );
  }

  MediatorGameRules copyWith({
    Set<String>? allowedTypes,
    bool? allowHistoricalNames,
    int? minPopulation,
    Set<String>? allowedCountryCodes,
  }) {
    return MediatorGameRules(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowHistoricalNames: allowHistoricalNames ?? this.allowHistoricalNames,
      minPopulation: minPopulation ?? this.minPopulation,
      allowedCountryCodes: allowedCountryCodes ?? this.allowedCountryCodes,
    );
  }
}
