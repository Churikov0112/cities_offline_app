part of 'countries_bloc.dart';

enum CountriesStatus { initial, loading, loaded, error }

class CountriesState {
  final List<(String code, String name)> countries;
  final CountriesStatus status;

  const CountriesState({
    this.countries = const [],
    this.status = CountriesStatus.initial,
  });

  const CountriesState.initial() : this();

  Map<String, dynamic> toJson() {
    return {
      'countries': countries
          .map((c) => {'code': c.$1, 'name': c.$2})
          .toList(growable: false),
      'status': status.name,
    };
  }

  factory CountriesState.fromJson(Map<String, dynamic> json) {
    final list = (json['countries'] as List<dynamic>?)
            ?.map(
              (e) => (
                (e as Map)['code'] as String,
                e['name'] as String,
              ),
            )
            .toList(growable: false) ??
        const [];
    return CountriesState(
      countries: list,
      status: CountriesStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CountriesStatus.initial,
      ),
    );
  }
}
