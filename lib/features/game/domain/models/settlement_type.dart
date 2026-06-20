enum SettlementType {
  city,
  town,
  village,
  hamlet;

  String get dbValue => name;

  static SettlementType fromDb(String value) {
    return SettlementType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => SettlementType.city,
    );
  }
}
