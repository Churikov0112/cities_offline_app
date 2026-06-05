import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../dictionary.dart';

part 'language_event.dart';
part 'language_state.dart';

@singleton
class LanguageBloc extends HydratedBloc<LanguageBlocEvent, LanguageState> {
  LanguageBloc() : super(const LanguageState(language: Languages.english)) {
    on<LanguageBlocEvent>(
      (event, emit) => switch (event) {
        LanguageBlocEventSet() => _set(event, emit),
      },
    );
  }

  Future<void> _set(LanguageBlocEventSet event, Emitter<LanguageState> emit) async {
    emit(LanguageState(language: event.language));
  }

  @override
  LanguageState fromJson(Map<String, dynamic>? json) {
    if (json?['language'] != null) {
      final value = Languages.values.firstWhere(
        (e) => e.name == json!['language'] as String,
        orElse: () => Languages.english,
      );
      return LanguageState(language: value);
    }
    return const LanguageState(language: Languages.english);
  }

  @override
  Map<String, dynamic>? toJson(LanguageState state) => <String, dynamic>{'language': state.language.name};
}
