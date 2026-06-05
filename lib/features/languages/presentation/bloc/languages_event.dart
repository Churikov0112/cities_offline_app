part of 'languages_bloc.dart';

sealed class LanguagesEvent {
  const LanguagesEvent();
}

class LanguagesLoadRequested extends LanguagesEvent {
  const LanguagesLoadRequested();
}
