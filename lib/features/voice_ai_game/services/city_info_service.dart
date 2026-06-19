import '../../../di/di.dart';
import '../../../services/localization/country_names.dart';
import '../../../services/localization/translator.dart';
import '../../ai_game/domain/models/ai_turn.dart';
import '../../mediator/domain/models/locality.dart';

class CityInfoService {
  Languages? _overrideLanguage;

  void setLanguage(Languages lang) => _overrideLanguage = lang;

  static Languages? languageFromLocale(String locale) {
    final code = locale.split('_').first;
    return switch (code) {
      'en' => Languages.english,
      'ru' => Languages.russian,
      'es' => Languages.spanish,
      'pt' => Languages.portuguese,
      'tr' => Languages.turkish,
      'fr' => Languages.french,
      'zh' => Languages.chinese,
      'ar' => Languages.arabic,
      'ja' => Languages.japanese,
      'hi' => Languages.hindi,
      'bn' => Languages.bengal,
      'de' => Languages.german,
      'ko' => Languages.korean,
      'it' => Languages.italian,
      'vi' => Languages.vietnamese,
      _ => null,
    };
  }

  static String localeForTts(String locale) => locale.replaceAll('_', '-');

  String populationText(Locality city) {
    final pop = city.population;
    if (pop == null) {
      return '${city.matchedName}: ${_ts(AppGlossary.populationUnknown, _voiceLang)}';
    }
    return _t(AppGlossary.voicePopulation, city.matchedName).replaceAll('{number}', _verbalize(pop));
  }

  String locationText(Locality city) {
    return _t(AppGlossary.voiceLocation, city.matchedName).replaceAll('{country}', _countryName(city));
  }

  String typeText(Locality city) {
    return _t(AppGlossary.voiceType, city.matchedName).replaceAll('{type}', _translateType(city.cityType));
  }

  String turnPrompt(String letter) {
    if (letter.isEmpty) return _ts(AppGlossary.voiceAnyCity, _voiceLang);
    return _ts(AppGlossary.voiceTurnPrompt, _voiceLang).replaceAll('{letter}', letter);
  }

  String aiRespondedText(String cityName, String letter) {
    return _t(AppGlossary.voiceAiResponded, cityName).replaceAll('{letter}', letter);
  }

  String cityRejectedText(String reason) {
    return _ts(AppGlossary.voiceCityRejected, _voiceLang).replaceAll('{reason}', reason);
  }

  String hintText(String cityName) {
    return _t(AppGlossary.voiceHint, cityName);
  }

  String notUnderstoodText(String letter) {
    return _ts(AppGlossary.voiceNotUnderstood, _voiceLang).replaceAll('{letter}', letter);
  }

  String quietText() {
    return _ts(AppGlossary.voiceQuiet, _voiceLang);
  }

  String surrenderAcceptedText() {
    return _ts(AppGlossary.voiceSurrenderAccepted, _voiceLang);
  }

  String youWonText() {
    return _ts(AppGlossary.voiceYouWon, _voiceLang);
  }

  String aiWonText() {
    return _ts(AppGlossary.voiceAiWon, _voiceLang);
  }

  String scoreText(int count) {
    return _ts(AppGlossary.voiceScore, _voiceLang).replaceAll('{count}', count.toString());
  }

  String welcomingText() {
    return _ts(AppGlossary.voiceWelcoming, _voiceLang);
  }

  String repeatTurnText(String letter) {
    return _ts(AppGlossary.voiceRepeatTurn, _voiceLang).replaceAll('{letter}', letter);
  }

  String noHintsText() => _ts(AppGlossary.voiceNoHints, _voiceLang);

  String couldNotIdentifyText() => _ts(AppGlossary.voiceCouldNotIdentify, _voiceLang);

  String listeningText() {
    return _ts(AppGlossary.voiceListening, _voiceLang);
  }

  String rejectReasonText(AiTurn turn) {
    final lang = _voiceLang;
    return switch (turn.rejectReason) {
      AiTurnRejectReason.emptyInput => _ts(AppGlossary.rejectEmptyInput, lang),
      AiTurnRejectReason.notFound => _ts(AppGlossary.rejectNotFound, lang),
      AiTurnRejectReason.alreadyUsed => _ts(AppGlossary.rejectAlreadyUsed, lang),
      AiTurnRejectReason.wrongStartLetter => _ts(
        AppGlossary.rejectWrongStartLetter,
        lang,
      ).replaceAll('{letter}', turn.expectedStartLetter ?? '?'),
      AiTurnRejectReason.typeNotAllowed => _ts(
        AppGlossary.rejectTypeNotAllowed,
        lang,
      ).replaceAll('{type}', turn.locality?.cityType ?? '?'),
      AiTurnRejectReason.oldNameNotAllowed => _ts(AppGlossary.rejectOldNameNotAllowed, lang),
      AiTurnRejectReason.belowMinPopulation => _ts(AppGlossary.rejectBelowMinPopulation, lang),
      AiTurnRejectReason.countryNotAllowed => _ts(
        AppGlossary.rejectCountryNotAllowed,
        lang,
      ).replaceAll('{country}', turn.locality?.country ?? '?'),
      null => _ts(AppGlossary.rejectDeclined, lang),
    };
  }

  String _verbalize(int pop) {
    if (pop >= 1000000) {
      final m = pop / 1000000;
      return '${m.toStringAsFixed(m == m.roundToDouble() ? 0 : 1)} ${_million(m)}';
    }
    if (pop >= 1000) {
      final k = pop / 1000;
      return '${k.toStringAsFixed(k == k.roundToDouble() ? 0 : 1)} ${_thousand(k)}';
    }
    return pop.toString();
  }

  String _million(double m) {
    final lang = _voiceLang;
    if (lang == Languages.russian) {
      if (m >= 5) return 'миллионов';
      if (m >= 2) return 'миллиона';
      return 'миллион';
    }
    return _millionTemplates[lang] ?? _millionTemplates[Languages.english]!;
  }

  String _thousand(double k) {
    final lang = _voiceLang;
    if (lang == Languages.russian) {
      if (k >= 5) return 'тысяч';
      if (k >= 2) return 'тысячи';
      return 'тысяча';
    }
    return _thousandTemplates[lang] ?? _thousandTemplates[Languages.english]!;
  }

  String _t(AppGlossary term, String city) {
    return _ts(term, _voiceLang).replaceAll('{city}', city);
  }

  Languages get _voiceLang => _overrideLanguage ?? getIt<LanguageBloc>().state.language;

  String _countryName(Locality city) {
    final lang = _voiceLang;
    return countryNames[city.countryCode.toLowerCase()]?[lang] ?? city.country;
  }

  String _translateType(String type) {
    return switch (type) {
      'city' => _ts(AppGlossary.city, _voiceLang),
      'town' => _ts(AppGlossary.town, _voiceLang),
      'village' => _ts(AppGlossary.village, _voiceLang),
      'hamlet' => _ts(AppGlossary.hamlet, _voiceLang),
      _ => type,
    };
  }

  String _ts(AppGlossary term, Languages lang) => dictionary[term]![lang]!;

  static const _millionTemplates = <Languages, String>{
    Languages.english: 'million',
    Languages.spanish: 'millones',
    Languages.portuguese: 'milhões',
    Languages.turkish: 'milyon',
    Languages.french: 'millions',
    Languages.chinese: '百万',
    Languages.arabic: 'مليون',
    Languages.japanese: '百万',
    Languages.hindi: 'मिलियन',
    Languages.bengal: 'মিলিয়ন',
    Languages.german: 'Millionen',
    Languages.korean: '백만',
    Languages.italian: 'milioni',
    Languages.vietnamese: 'triệu',
  };

  static const _thousandTemplates = <Languages, String>{
    Languages.english: 'thousand',
    Languages.spanish: 'mil',
    Languages.portuguese: 'mil',
    Languages.turkish: 'bin',
    Languages.french: 'mille',
    Languages.chinese: '千',
    Languages.arabic: 'ألف',
    Languages.japanese: '千',
    Languages.hindi: 'हज़ार',
    Languages.bengal: 'হাজার',
    Languages.german: 'tausend',
    Languages.korean: '천',
    Languages.italian: 'mila',
    Languages.vietnamese: 'nghìn',
  };
}
