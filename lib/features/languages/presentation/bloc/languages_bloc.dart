import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../mediator/domain/repos/cities_repository.dart';
import '../../domain/models/available_language.dart';

part 'languages_event.dart';
part 'languages_state.dart';

@singleton
class LanguagesBloc extends HydratedBloc<LanguagesEvent, LanguagesState> {
  final CitiesRepository _citiesRepository;

  LanguagesBloc({required CitiesRepository citiesRepository})
    : _citiesRepository = citiesRepository,
      super(const LanguagesState.initial()) {
    on<LanguagesLoadRequested>(_onLoadRequested);
  }

  Future<void> loadIfNeeded() async {
    if (state.status == LanguagesStatus.loaded) {
      return;
    }

    final future = stream.firstWhere(
      (s) =>
          s.status == LanguagesStatus.loaded ||
          s.status == LanguagesStatus.error,
    );
    add(const LanguagesLoadRequested());
    await future;
  }

  Future<void> _onLoadRequested(
    LanguagesLoadRequested event,
    Emitter<LanguagesState> emit,
  ) async {
    if (state.status == LanguagesStatus.loaded ||
        state.status == LanguagesStatus.loading) {
      return;
    }

    emit(const LanguagesState(status: LanguagesStatus.loading));

    try {
      final codes = await _citiesRepository.loadAvailableLanguages();
      emit(LanguagesState(
        languages: codes.map(AvailableLanguage.fromCode).toList(),
        status: LanguagesStatus.loaded,
      ));
    } catch (_) {
      emit(const LanguagesState(status: LanguagesStatus.error));
    }
  }

  @override
  LanguagesState? fromJson(Map<String, dynamic> json) {
    return LanguagesState.fromJson(json);
  }

  @override
  Map<String, dynamic>? toJson(LanguagesState state) {
    if (state.status == LanguagesStatus.loaded) {
      return state.toJson();
    }
    return null;
  }
}
