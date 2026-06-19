import '../../mediator/domain/repos/cities_repository.dart';
import '../../../services/localization/dictionary.dart';
import 'intent_lexemes.dart';

class CommandParser {
  final CitiesRepository _repo;
  final VoiceLanguage _voiceLang;

  CommandParser({
    required CitiesRepository repo,
    required Languages uiLanguage,
  }) : _repo = repo,
       _voiceLang = _mapLanguage(uiLanguage);

  static VoiceLanguage _mapLanguage(Languages lang) {
    return switch (lang) {
      Languages.english => VoiceLanguage.english,
      Languages.russian => VoiceLanguage.russian,
      Languages.spanish => VoiceLanguage.spanish,
      Languages.portuguese => VoiceLanguage.portuguese,
      Languages.turkish => VoiceLanguage.turkish,
      Languages.french => VoiceLanguage.french,
      Languages.chinese => VoiceLanguage.chinese,
      Languages.arabic => VoiceLanguage.arabic,
      Languages.japanese => VoiceLanguage.japanese,
      Languages.hindi => VoiceLanguage.hindi,
      Languages.bengal => VoiceLanguage.bengal,
      Languages.german => VoiceLanguage.german,
      Languages.korean => VoiceLanguage.korean,
      Languages.italian => VoiceLanguage.italian,
      Languages.vietnamese => VoiceLanguage.vietnamese,
    };
  }

  Future<VoiceCommand> parse(String text) async {
    final trimmed = text.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return const VoiceCommand(intent: VoiceIntent.unknown, rawText: '');
    }

    final intent = IntentLexemes.classify(trimmed, _voiceLang);

    if (intent == VoiceIntent.unknown) {
      final city = await extractCityName(trimmed);
      if (city != null) {
        return VoiceCommand(intent: VoiceIntent.cityName, rawText: city);
      }
    }

    return VoiceCommand(intent: intent, rawText: trimmed);
  }

  Future<String?> extractCityName(String text) async {
    final words = text.toLowerCase().split(RegExp(r'[\s,;:.!?]+'));
    final stopWords = IntentLexemes.stopWordsFor(_voiceLang);

    for (final word in words) {
      if (stopWords.contains(word) || word.length < 2) {
        continue;
      }
      if (IntentLexemes.isTriggerWord(word)) {
        continue;
      }

      final city = await _repo.findLocalityByName(word);
      if (city != null) {
        return city.matchedName;
      }

      if (_voiceLang == VoiceLanguage.russian && word.length > 4) {
        final stemmed = IntentLexemes.stripRussianEndings(word);
        if (stemmed != word && stemmed.length >= 3) {
          final city2 = await _repo.findLocalityByName(stemmed);
          if (city2 != null) {
            return city2.matchedName;
          }
        }
      }
    }
    return null;
  }
}
