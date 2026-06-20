import 'settlement_type.dart';

class GameRules {
  final Set<SettlementType> allowedTypes;
  final bool allowHistoricalNames;
  final int minPopulation;
  final String? preferredLanguage;
  final Set<String> allowedCountryCodes;

  const GameRules({
    required this.allowedTypes,
    required this.allowHistoricalNames,
    required this.minPopulation,
    this.preferredLanguage,
    this.allowedCountryCodes = const {},
  });

  GameRules.onlyCities()
    : allowedTypes = {SettlementType.city, SettlementType.town},
      allowHistoricalNames = false,
      minPopulation = 0,
      preferredLanguage = null,
      allowedCountryCodes = const {};

  bool isAllowedType(SettlementType type) => allowedTypes.contains(type);

  bool isAllowedTypeFromString(String type) {
    return allowedTypes.contains(SettlementType.fromDb(type));
  }

  bool isAllowedCountry(String countryCode) =>
      allowedCountryCodes.isEmpty ||
      allowedCountryCodes.contains(countryCode.toLowerCase());

  Set<String> get allowedTypeStrings =>
      allowedTypes.map((e) => e.dbValue).toSet();

  Map<String, dynamic> toJson() {
    return {
      'allowedTypes': allowedTypes.map((e) => e.name).toList(),
      'allowHistoricalNames': allowHistoricalNames,
      'minPopulation': minPopulation,
      'preferredLanguage': preferredLanguage,
      'allowedCountryCodes': allowedCountryCodes.toList(),
    };
  }

  factory GameRules.fromJson(Map<String, dynamic> json) {
    final raw = ((json['allowedTypes'] as List<dynamic>?) ??
        const ['city', 'town'])
        .map((e) => e.toString().toLowerCase())
        .toSet();
    return GameRules(
      allowedTypes: raw.map((e) => SettlementType.fromDb(e)).toSet(),
      allowHistoricalNames: json['allowHistoricalNames'] as bool? ?? false,
      minPopulation: json['minPopulation'] as int? ?? 0,
      preferredLanguage: json['preferredLanguage'] as String?,
      allowedCountryCodes:
          ((json['allowedCountryCodes'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString().toLowerCase())
              .toSet(),
    );
  }

  GameRules copyWith({
    Set<SettlementType>? allowedTypes,
    bool? allowHistoricalNames,
    int? minPopulation,
    String? preferredLanguage,
    Set<String>? allowedCountryCodes,
  }) {
    return GameRules(
      allowedTypes: allowedTypes ?? this.allowedTypes,
      allowHistoricalNames: allowHistoricalNames ?? this.allowHistoricalNames,
      minPopulation: minPopulation ?? this.minPopulation,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      allowedCountryCodes: allowedCountryCodes ?? this.allowedCountryCodes,
    );
  }
}
