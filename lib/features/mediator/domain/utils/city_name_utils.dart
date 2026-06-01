import 'package:characters/characters.dart';
import 'package:diacritic/diacritic.dart';

const Set<String> ignoredTrailingLetters = {'ь', 'ъ', 'ы', '-', ' ', "'"};

String normalizeCityNameForSearch(String value) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty) {
    return '';
  }

  // Keep runtime normalization aligned with DB-build script (NFKD + remove marks).
  // In particular: "й" -> "и", "ё" -> "е".
  final scriptAligned = lower.replaceAll('й', 'и').replaceAll('ё', 'е');
  final withoutDiacritics = removeDiacritics(scriptAligned);
  return withoutDiacritics.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
}

String capitalizeFirst(String value) {
  if (value.isEmpty) {
    return value;
  }
  final first = value[0].toUpperCase();
  final rest = value.length > 1 ? value.substring(1) : '';
  return '$first$rest';
}

Set<String> buildCityQueryVariants(String raw) {
  final normalizedSpaces = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  final normalizedHyphens = normalizedSpaces.replaceAll(
    RegExp(r'\s*-\s*'),
    '-',
  );

  final tokens = normalizedHyphens
      .split(RegExp(r'[\s-]+'))
      .where((token) => token.isNotEmpty)
      .toList();

  final variants = <String>{
    raw,
    normalizedSpaces,
    normalizedHyphens,
    capitalizeFirst(normalizedSpaces),
    capitalizeFirst(normalizedHyphens),
  };

  if (tokens.isNotEmpty) {
    final titleCaseTokens = tokens.map(capitalizeFirst).toList();
    final joined = tokens.join();
    final joinedTitle = titleCaseTokens.join();

    variants.add(tokens.join(' '));
    variants.add(tokens.join('-'));
    variants.add(joined);
    variants.add(titleCaseTokens.join(' '));
    variants.add(titleCaseTokens.join('-'));
    variants.add(joinedTitle);

    if (tokens.length == 1 && tokens.first.characters.length >= 6) {
      final word = tokens.first;
      final splitIndex = bestSplitIndex(word);
      if (splitIndex != null) {
        final left = word.substring(0, splitIndex);
        final right = word.substring(splitIndex);
        variants.add('$left $right');
        variants.add('$left-$right');
        variants.add('${capitalizeFirst(left)} ${capitalizeFirst(right)}');
        variants.add('${capitalizeFirst(left)}-${capitalizeFirst(right)}');
      }
    }

    if (tokens.length >= 3) {
      for (var i = 1; i < tokens.length - 1; i++) {
        if (tokens[i] == 'на') {
          final left = tokens.sublist(0, i).join('-');
          final right = tokens.sublist(i + 1).join('-');
          variants.add('$left-на-$right');
          variants.add(
            '${left.split('-').map(capitalizeFirst).join('-')}-'
            'На-'
            '${right.split('-').map(capitalizeFirst).join('-')}',
          );
        }
      }
    }

    final caseTokenVariants = buildTokenCaseVariants(tokens);
    for (final tokenVariant in caseTokenVariants) {
      variants.add(tokenVariant.join(' '));
      variants.add(tokenVariant.join('-'));
    }
  }

  return variants
      .map((v) => v.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((v) => v.isNotEmpty)
      .toSet();
}

Set<List<String>> buildTokenCaseVariants(List<String> tokens) {
  var acc = <List<String>>{<String>[]};

  for (final token in tokens) {
    final options = <String>{
      token,
      token.toLowerCase(),
      capitalizeFirst(token),
    };
    final next = <List<String>>{};
    for (final prefix in acc) {
      for (final opt in options) {
        next.add([...prefix, opt]);
      }
    }
    acc = next;
  }

  return acc;
}

int? bestSplitIndex(String word) {
  if (word.characters.length < 6) {
    return null;
  }

  final middle = word.length ~/ 2;
  if (middle <= 2 || middle >= word.length - 2) {
    return null;
  }
  return middle;
}

String? firstLetter(String value) {
  final normalized = normalizeCityNameForSearch(value);
  if (normalized.isEmpty) {
    return null;
  }
  return normalized.characters.first.toLowerCase();
}

String? lastSignificantLetter(String value) {
  final trimmed = normalizeCityNameForSearch(value);
  if (trimmed.isEmpty) {
    return null;
  }

  final chars = trimmed.characters.toList();
  for (var i = chars.length - 1; i >= 0; i--) {
    final ch = chars[i];
    if (ignoredTrailingLetters.contains(ch)) {
      continue;
    }
    if (RegExp(r'^[\p{L}]$', unicode: true).hasMatch(ch)) {
      return ch;
    }
  }
  return null;
}

bool areLettersCompatible(String actual, String expected) {
  return letterKey(actual) == letterKey(expected);
}

const Map<String, String> _letterKeyMap = {
  'a': 'a',
  'а': 'a',
  'b': 'b',
  'б': 'b',
  'c': 'c',
  'ц': 'c',
  'd': 'd',
  'д': 'd',
  'e': 'e',
  'е': 'e',
  'ё': 'e',
  'э': 'e',
  'f': 'f',
  'ф': 'f',
  'g': 'g',
  'г': 'g',
  'h': 'h',
  'х': 'h',
  'i': 'i',
  'и': 'i',
  'й': 'i',
  'j': 'j',
  'k': 'k',
  'к': 'k',
  'l': 'l',
  'л': 'l',
  'm': 'm',
  'м': 'm',
  'n': 'n',
  'н': 'n',
  'o': 'o',
  'о': 'o',
  'p': 'p',
  'п': 'p',
  'q': 'q',
  'r': 'r',
  'р': 'r',
  's': 's',
  'с': 's',
  't': 't',
  'т': 't',
  'u': 'u',
  'у': 'u',
  'v': 'v',
  'в': 'v',
  'w': 'w',
  'x': 'x',
  'y': 'y',
  'ы': 'y',
  'z': 'z',
  'з': 'z',
  'ж': 'z',
  'ч': 'c',
  'ш': 's',
  'щ': 's',
  'ю': 'u',
  'я': 'a',
};

String letterKey(String letter) {
  return _letterKeyMap[letter] ?? letter;
}

String compatibilityKey(String value) {
  final normalized = normalizeCityNameForSearch(value);
  if (normalized.isEmpty) {
    return '';
  }

  final chars = normalized.characters;
  final buffer = StringBuffer();
  for (final ch in chars) {
    buffer.write(letterKey(ch));
  }
  return buffer.toString();
}

Set<String> equivalentLettersForSearch(String letter) {
  final key = letterKey(letter.toLowerCase());
  final result = <String>{};

  for (final entry in _letterKeyMap.entries) {
    if (entry.value == key) {
      result.add(entry.key);
    }
  }

  if (result.isEmpty && letter.isNotEmpty) {
    result.add(letter.toLowerCase());
  }

  return result;
}
