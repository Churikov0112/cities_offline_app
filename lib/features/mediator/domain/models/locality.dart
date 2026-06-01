class Locality {
  final String id;
  final String name;
  final String matchedName;
  final String matchedLang;
  final String displayName;
  final String cityType;
  final String countryCode;
  final String country;
  final String state;
  final double? lat;
  final double? lon;
  final int? population;

  const Locality({
    required this.id,
    required this.name,
    required this.matchedName,
    required this.matchedLang,
    required this.displayName,
    required this.cityType,
    required this.countryCode,
    required this.country,
    required this.state,
    required this.lat,
    required this.lon,
    required this.population,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'matchedName': matchedName,
      'matchedLang': matchedLang,
      'displayName': displayName,
      'cityType': cityType,
      'countryCode': countryCode,
      'country': country,
      'state': state,
      'lat': lat,
      'lon': lon,
      'population': population,
    };
  }

  factory Locality.fromJson(Map<String, dynamic> json) {
    return Locality(
      id: json['id'] as String,
      name: json['name'] as String,
      matchedName: json['matchedName'] as String,
      matchedLang: json['matchedLang'] as String? ?? 'default',
      displayName: json['displayName'] as String? ?? '',
      cityType: json['cityType'] as String? ?? 'unknown',
      countryCode: json['countryCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
      state: json['state'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
      population: (json['population'] as num?)?.toInt(),
    );
  }
}
