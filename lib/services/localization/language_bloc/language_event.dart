part of 'language_bloc.dart';

sealed class LanguageBlocEvent {}

class LanguageBlocEventSet implements LanguageBlocEvent {
  final Languages language;

  const LanguageBlocEventSet({required this.language});
}
