const _metaCodes = <String>{
  'adjective',
  'alt_name',
  'genitive',
  'iso15919',
  'other',
  'pronunciation',
  'carnaval',
  'gem',
  'md',
  'win',
  'simple',
  'und',
  'mis',
  'en1',
  'en2',
  'en3',
  'en4',
  'en5',
  'ar1',
  'he1',
};

const _latnVariants = <String>{
  'bo-Latn-thl', 'bo-Latn-wylie', 'ja-Latn', 'ja-Hira', 'ja_kana', 'ja_rm',
  'ko-Latn', 'ko-Hani', 'lo-Latn', 'nan-Latn-pehoeji', 'nan-Latn-tailo',
  'yue-Latn', 'yue-Latn-HK', 'yue-Latn-jyutping', 'zh-Latn-pinyin',
  'kk-Latn', 'uz-Latn',
};

const _arabVariants = <String>{
  'kk-Arab', 'ky-Arab', 'ku-Arab', 'pa-Arab', 'tk-Arab', 'uz-Arab',
  'crh-Arab', 'kab-Arab', 'az-Arab', 'ms-Arab',
};

const _cyrVariants = <String>{
  'kk-Cyrl', 'ky-Cyrl', 'uz-Cyrl', 'mn-Cyrl', 'az-cyr', 'crh-cyr', 'sr-Cyrl',
};

bool isUILanguage(String code) {
  if (_metaCodes.contains(code)) return false;
  if (code.contains(':')) return false;
  if (RegExp(r'^[a-z]+[0-9]+$').hasMatch(code)) return false;
  if (code == 'fr-x-gallo' || code == 'zh-Latn-pinyin' || code == 'zh_min_nan') return false;
  if (code.contains('-Latn') || code.endsWith('_kana') || code.endsWith('_rm')) {
    if (_latnVariants.contains(code)) return false;
  }
  if (code.contains('-Arab') && !_arabVariants.contains(code)) return false;
  if ((code.contains('-Cyrl') || code.endsWith('-cyr')) && !_cyrVariants.contains(code)) return false;
  if (code == 'zh-Hans' || code == 'zh-Hant' || code == 'nan-Hant' || code == 'yue-Hant') return true;
  return true;
}

String parentLanguageCode(String code) {
  const direct = <String, String>{
    'en1': 'en', 'en2': 'en', 'en3': 'en', 'en4': 'en', 'en5': 'en',
    'simple': 'en', 'ang': 'en', 'enm': 'en',
    'ar1': 'ar',
    'he1': 'he',
    'ja-Hira': 'ja', 'ja-Latn': 'ja', 'ja_kana': 'ja', 'ja_rm': 'ja',
    'ko-Hani': 'ko', 'ko-Latn': 'ko',
    'zh-Latn-pinyin': 'zh',
    'nan-Latn-pehoeji': 'nan', 'nan-Latn-tailo': 'nan',
    'yue-Latn': 'yue', 'yue-Latn-HK': 'yue', 'yue-Latn-jyutping': 'yue',
    'bo-Latn-thl': 'bo', 'bo-Latn-wylie': 'bo',
    'kk-Arab': 'kk', 'kk-Cyrl': 'kk', 'kk-Latn': 'kk',
    'ky-Arab': 'ky', 'ky-Cyrl': 'ky',
    'uz-Arab': 'uz', 'uz-Cyrl': 'uz', 'uz-Latn': 'uz',
    'az-Arab': 'az', 'az-cyr': 'az',
    'crh-Arab': 'crh', 'crh-cyr': 'crh',
    'sr-Latn': 'sr', 'sr-Cyrl': 'sr',
    'mn-Cyrl': 'mn', 'mn-Mong': 'mn',
    'pa-Arab': 'pa', 'tk-Arab': 'tk', 'kab-Arab': 'kab', 'ku-Arab': 'ku',
    'be-tarask': 'be',
    'en-CA': 'en', 'en-GB': 'en',
    'de-AT': 'de', 'de-CH': 'de',
    'nl-BE': 'nl',
    'pt-BR': 'pt', 'pt-PT': 'pt',
    'zh-Hans': 'zh', 'zh-Hant': 'zh',
    'nan-Hant': 'nan', 'yue-Hant': 'yue',
    'zh-hant': 'zh',
  };
  return direct[code] ?? code;
}

List<(String, List<String>)> groupLanguages(List<String> codes) {
  final groups = <String, List<String>>{};
  for (final code in codes) {
    final parent = parentLanguageCode(code);
    groups.putIfAbsent(parent, () => []);
    if (code != parent) {
      groups[parent]!.add(code);
    }
  }
  for (final code in codes) {
    groups.putIfAbsent(code, () => []);
  }
  final result = groups.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return result.map((e) => (e.key, e.value)).toList();
}
