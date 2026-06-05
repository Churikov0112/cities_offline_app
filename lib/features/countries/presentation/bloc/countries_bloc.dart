import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../mediator/domain/repos/cities_repository.dart';

part 'countries_event.dart';
part 'countries_state.dart';

@singleton
class CountriesBloc extends HydratedBloc<CountriesEvent, CountriesState> {
  final CitiesRepository _citiesRepository;

  CountriesBloc({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository,
      super(const CountriesState.initial()) {
    on<CountriesLoadRequested>(_onLoadRequested);
  }

  Future<void> loadIfNeeded() async {
    if (state.status == CountriesStatus.loaded) {
      return;
    }

    final future = stream.firstWhere(
      (s) => s.status == CountriesStatus.loaded || s.status == CountriesStatus.error,
    );
    add(const CountriesLoadRequested());
    await future;
  }

  Future<void> _onLoadRequested(
    CountriesLoadRequested event,
    Emitter<CountriesState> emit,
  ) async {
    if (state.status == CountriesStatus.loaded || state.status == CountriesStatus.loading) {
      return;
    }

    emit(const CountriesState(status: CountriesStatus.loading));

    try {
      final countries = await _citiesRepository.loadAvailableCountries();
      emit(
        CountriesState(
          countries: countries,
          status: CountriesStatus.loaded,
        ),
      );
    } catch (_) {
      emit(const CountriesState(status: CountriesStatus.error));
    }
  }

  @override
  CountriesState? fromJson(Map<String, dynamic> json) {
    return CountriesState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(CountriesState state) {
    if (state.status == CountriesStatus.loaded) {
      return state.toJson();
    }
    return null;
  }
}
