part of 'languages_bloc.dart';

enum LanguagesStatus { initial, loading, loaded, error }

class LanguagesState {
  final List<AvailableLanguage> languages;
  final LanguagesStatus status;

  const LanguagesState({
    this.languages = const [],
    this.status = LanguagesStatus.initial,
  });

  const LanguagesState.initial()
    : languages = const [],
      status = LanguagesStatus.initial;

  LanguagesState copyWith({
    List<AvailableLanguage>? languages,
    LanguagesStatus? status,
  }) {
    return LanguagesState(
      languages: languages ?? this.languages,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'languages': languages.map((l) => l.toJson()).toList(),
      'status': status.name,
    };
  }

  factory LanguagesState.fromJson(Map<String, dynamic> json) {
    final rawLanguages = json['languages'] as List<dynamic>? ?? const [];
    final languages = rawLanguages.map((e) {
      if (e is Map<String, dynamic>) {
        return AvailableLanguage.fromJson(e);
      }
      // backward compat: old format stored plain strings
      return AvailableLanguage.fromCode(e as String);
    }).toList();
    return LanguagesState(
      languages: languages,
      status: LanguagesStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => LanguagesStatus.loaded,
      ),
    );
  }
}
