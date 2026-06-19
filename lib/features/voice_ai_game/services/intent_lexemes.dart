enum VoiceIntent {
  cityName,
  hint,
  surrender,
  repeat,
  score,
  population,
  location,
  type,
  unknown,
}

class VoiceCommand {
  final VoiceIntent intent;
  final String rawText;

  const VoiceCommand({required this.intent, required this.rawText});
}

enum VoiceLanguage {
  english,
  russian,
  spanish,
  portuguese,
  turkish,
  french,
  chinese,
  arabic,
  japanese,
  hindi,
  bengal,
  german,
  korean,
  italian,
  vietnamese,
}

class IntentLexemes {
  static bool _isCjk(VoiceLanguage lang) {
    return switch (lang) {
      VoiceLanguage.chinese || VoiceLanguage.japanese || VoiceLanguage.korean =>
        true,
      _ => false,
    };
  }

  static bool _match(String word, String trigger, VoiceLanguage lang) {
    final w = word.toLowerCase();
    final t = trigger.toLowerCase();
    if (_isCjk(lang)) {
      return w.contains(t);
    }
    final len = w.length > 6 ? 6 : w.length;
    final stem = w.substring(0, len);
    final tLen = t.length > 6 ? 6 : t.length;
    final tStem = t.substring(0, tLen);
    return stem.startsWith(tStem) || tStem.startsWith(stem);
  }

  static VoiceIntent classify(String text, VoiceLanguage lang) {
    final words = text.toLowerCase().split(RegExp(r'[\s,;:.!?]+'));

    final scores = <VoiceIntent, int>{};
    for (final word in words) {
      for (final entry in _triggers.entries) {
        final triggers = entry.value[lang] ?? <String>{};
        if (triggers.any((t) => _match(word, t, lang))) {
          scores[entry.key] = (scores[entry.key] ?? 0) + 1;
        }
      }
    }

    if (scores.isEmpty) return VoiceIntent.unknown;

    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static Set<String> stopWordsFor(VoiceLanguage lang) {
    return _stopWords[lang] ?? <String>{};
  }

  static String stripRussianEndings(String word) {
    if (word.length < 4) return word;
    const suffixes = ['ами', 'ями', 'ов', 'ев', 'ей', 'ия', 'ья',
      'ый', 'ой', 'ая', 'ые', 'ие', 'ое', 'ые',
      'ого', 'его', 'ому', 'ему', 'ым', 'им',
      'ом', 'ем', 'ую', 'юю', 'ых', 'их',
      'а', 'я', 'у', 'ю', 'о', 'е', 'ы', 'и', 'й', 'ь'];
    for (final s in suffixes) {
      if (word.length > s.length && word.endsWith(s)) {
        return word.substring(0, word.length - s.length);
      }
    }
    return word;
  }

  static bool isTriggerWord(String word) {
    final w = word.toLowerCase();
    for (final map in _triggers.values) {
      for (final set in map.values) {
        if (set.contains(w)) return true;
      }
    }
    return false;
  }

  static final Map<VoiceIntent, Map<VoiceLanguage, Set<String>>> _triggers = {
    VoiceIntent.population: {
      VoiceLanguage.english: {'population', 'people', 'inhabitants', 'how many', 'residents'},
      VoiceLanguage.russian: {'населен', 'жител', 'люд', 'сколько', 'народ'},
      VoiceLanguage.spanish: {'población', 'habitantes', 'gente', 'cuántos', 'poblacional'},
      VoiceLanguage.portuguese: {'população', 'habitantes', 'pessoas', 'quantos'},
      VoiceLanguage.turkish: {'nüfus', 'insan', 'kaç', 'kişi'},
      VoiceLanguage.french: {'population', 'habitants', 'gens', 'combien'},
      VoiceLanguage.chinese: {'人口', '居民', '多少人'},
      VoiceLanguage.arabic: {'السكان', 'عدد السكان', 'كم', 'نسمة'},
      VoiceLanguage.japanese: {'人口', '住民', '何人'},
      VoiceLanguage.hindi: {'जनसंख्या', 'लोग', 'कितने', 'आबादी'},
      VoiceLanguage.bengal: {'জনসংখ্যা', 'লোক', 'কত', 'বাসিন্দা'},
      VoiceLanguage.german: {'bevölkerung', 'einwohner', 'leute', 'wie viele'},
      VoiceLanguage.korean: {'인구', '사람', '몇', '주민'},
      VoiceLanguage.italian: {'popolazione', 'abitanti', 'persone', 'quanti'},
      VoiceLanguage.vietnamese: {'dân số', 'người', 'bao nhiêu'},
    },
    VoiceIntent.location: {
      VoiceLanguage.english: {'where', 'located', 'country', 'coordinates'},
      VoiceLanguage.russian: {'где', 'находит', 'координат', 'стран', 'регион'},
      VoiceLanguage.spanish: {'dónde', 'ubicado', 'país', 'coordenadas'},
      VoiceLanguage.portuguese: {'onde', 'localizado', 'país', 'coordenadas'},
      VoiceLanguage.turkish: {'nerede', 'bulunur', 'ülke', 'koordinat'},
      VoiceLanguage.french: {'où', 'situé', 'pays', 'coordonnées'},
      VoiceLanguage.chinese: {'哪里', '位于', '国家', '坐标'},
      VoiceLanguage.arabic: {'أين', 'يقع', 'بلد', 'إحداثيات'},
      VoiceLanguage.japanese: {'どこ', '位置', '国', '座標'},
      VoiceLanguage.hindi: {'कहाँ', 'स्थित', 'देश', 'निर्देशांक'},
      VoiceLanguage.bengal: {'কোথায়', 'অবস্থিত', 'দেশ', 'স্থানাঙ্ক'},
      VoiceLanguage.german: {'wo', 'befindet', 'land', 'koordinaten'},
      VoiceLanguage.korean: {'어디', '위치', '나라', '좌표'},
      VoiceLanguage.italian: {'dove', 'situato', 'paese', 'coordinate'},
      VoiceLanguage.vietnamese: {'ở đâu', 'nằm', 'quốc gia', 'tọa độ'},
    },
    VoiceIntent.type: {
      VoiceLanguage.english: {'city', 'town', 'village', 'type', 'settlement', 'hamlet'},
      VoiceLanguage.russian: {'город', 'село', 'деревн', 'поселок', 'тип', 'населён'},
      VoiceLanguage.spanish: {'ciudad', 'pueblo', 'aldea', 'tipo'},
      VoiceLanguage.portuguese: {'cidade', 'vila', 'aldeia', 'tipo'},
      VoiceLanguage.turkish: {'şehir', 'kasaba', 'köy', 'tip'},
      VoiceLanguage.french: {'ville', 'village', 'hameau', 'type'},
      VoiceLanguage.chinese: {'城市', '城镇', '村庄', '类型'},
      VoiceLanguage.arabic: {'مدينة', 'بلدة', 'قرية', 'نوع'},
      VoiceLanguage.japanese: {'都市', '町', '村', '種類'},
      VoiceLanguage.hindi: {'शहर', 'कस्बा', 'गाँव', 'प्रकार'},
      VoiceLanguage.bengal: {'শহর', ' town ', 'গ্রাম', 'ধরন'},
      VoiceLanguage.german: {'stadt', 'dorf', 'ort', 'typ'},
      VoiceLanguage.korean: {'도시', '마을', '종류'},
      VoiceLanguage.italian: {'città', 'paese', 'villaggio', 'tipo'},
      VoiceLanguage.vietnamese: {'thành phố', 'thị trấn', 'làng', 'loại'},
    },
    VoiceIntent.hint: {
      VoiceLanguage.english: {'hint', 'help', 'suggestion', 'give me', 'clue'},
      VoiceLanguage.russian: {'подсказ', 'помог', 'совет', 'предлож', 'иде'},
      VoiceLanguage.spanish: {'pista', 'ayuda', 'sugerencia', 'consejo'},
      VoiceLanguage.portuguese: {'dica', 'ajuda', 'sugestão'},
      VoiceLanguage.turkish: {'ipucu', 'yardım', 'öneri', 'fikri'},
      VoiceLanguage.french: {'indice', 'aide', 'suggestion', 'conseil'},
      VoiceLanguage.chinese: {'提示', '帮助', '建议', '线索'},
      VoiceLanguage.arabic: {'تلميح', 'مساعدة', 'اقتراح'},
      VoiceLanguage.japanese: {'ヒント', '助け', '提案'},
      VoiceLanguage.hindi: {'संकेत', 'मदद', 'सुझाव'},
      VoiceLanguage.bengal: {'ইঙ্গিত', 'সাহায্য', 'পরামর্শ'},
      VoiceLanguage.german: {'tipp', 'hilfe', 'vorschlag'},
      VoiceLanguage.korean: {'힌트', '도움', '제안'},
      VoiceLanguage.italian: {'suggerimento', 'aiuto', 'consiglio'},
      VoiceLanguage.vietnamese: {'gợi ý', 'giúp', 'đề xuất'},
    },
    VoiceIntent.surrender: {
      VoiceLanguage.english: {'surrender', 'give up', 'quit', 'stop', 'enough'},
      VoiceLanguage.russian: {'сдаюсь', 'сдаться', 'хватит', 'законч', 'стоп'},
      VoiceLanguage.spanish: {'rendirse', 'renunciar', 'suficiente', 'parar'},
      VoiceLanguage.portuguese: {'desisto', 'desistir', 'chega', 'parar'},
      VoiceLanguage.turkish: {'pes ettim', 'bırak', 'yeter', 'dur'},
      VoiceLanguage.french: {'abandonner', 'arrêter', 'assez', 'stop'},
      VoiceLanguage.chinese: {'投降', '放弃', '够了', '停止'},
      VoiceLanguage.arabic: {'استسلم', 'توقف', 'كفى'},
      VoiceLanguage.japanese: {'降参', 'やめる', '十分'},
      VoiceLanguage.hindi: {'हार', 'छोड़ो', 'बस'},
      VoiceLanguage.bengal: {'হালছেড়ে', 'ছাড়ো', 'থামো'},
      VoiceLanguage.german: {'aufgeben', 'schluss', 'genug', 'stopp'},
      VoiceLanguage.korean: {'포기', '그만', '관둬'},
      VoiceLanguage.italian: {'arrendersi', 'rinunciare', 'basta', 'stop'},
      VoiceLanguage.vietnamese: {'bỏ cuộc', 'dừng', 'đủ'},
    },
    VoiceIntent.repeat: {
      VoiceLanguage.english: {'repeat', 'again', 'say again', 'what letter', 'what was'},
      VoiceLanguage.russian: {'повтор', 'ещё раз', 'забуд', 'какая букв'},
      VoiceLanguage.spanish: {'repetir', 'otra vez', 'qué letra'},
      VoiceLanguage.portuguese: {'repetir', 'novamente', 'qual letra'},
      VoiceLanguage.turkish: {'tekrar', 'bir daha', 'hangi harf'},
      VoiceLanguage.french: {'répéter', 'encore', 'quelle lettre'},
      VoiceLanguage.chinese: {'重复', '再次', '什么字母'},
      VoiceLanguage.arabic: {'كرر', 'مرة أخرى', 'أي حرف'},
      VoiceLanguage.japanese: {'繰り返し', 'もう一度', '何の文字'},
      VoiceLanguage.hindi: {'दोहराना', 'फिर से', 'कौन सा अक्षर'},
      VoiceLanguage.bengal: {'পুনরাবৃত্তি', 'আবার', 'কোন অক্ষর'},
      VoiceLanguage.german: {'wiederholen', 'nochmal', 'welcher buchstabe'},
      VoiceLanguage.korean: {'반복', '다시', '무슨 글자'},
      VoiceLanguage.italian: {'ripetere', 'ancora', 'che lettera'},
      VoiceLanguage.vietnamese: {'lặp lại', 'lần nữa', 'chữ gì'},
    },
    VoiceIntent.score: {
      VoiceLanguage.english: {'score', 'count', 'how many cities', 'statistics', 'my score'},
      VoiceLanguage.russian: {'счёт', 'счет', 'сколько город', 'статистик'},
      VoiceLanguage.spanish: {'puntuación', 'cuántas ciudades', 'estadística'},
      VoiceLanguage.portuguese: {'pontuação', 'quantas cidades', 'estatística'},
      VoiceLanguage.turkish: {'skor', 'kaç şehir', 'istatistik'},
      VoiceLanguage.french: {'score', 'combien de villes', 'statistique'},
      VoiceLanguage.chinese: {'分数', '多少个城市', '统计'},
      VoiceLanguage.arabic: {'النتيجة', 'كم مدينة', 'إحصائيات'},
      VoiceLanguage.japanese: {'スコア', 'いくつの都市', '統計'},
      VoiceLanguage.hindi: {'स्कोर', 'कितने शहर', 'आँकड़े'},
      VoiceLanguage.bengal: {'স্কোর', 'কতটি শহর', 'পরিসংখ্যান'},
      VoiceLanguage.german: {'punktzahl', 'wie viele städte', 'statistik'},
      VoiceLanguage.korean: {'점수', '몇 개 도시', '통계'},
      VoiceLanguage.italian: {'punteggio', 'quante città', 'statistica'},
      VoiceLanguage.vietnamese: {'điểm', 'bao nhiêu thành phố', 'thống kê'},
    },
  };

  static const Map<VoiceLanguage, Set<String>> _stopWords = {
    VoiceLanguage.english: {
      'the', 'a', 'an', 'is', 'are', 'was', 'at', 'in', 'on', 'and', 'or',
      'this', 'that', 'these', 'those', 'for', 'to', 'of', 'with', 'it', 'its',
      'my', 'your', 'his', 'her', 'our', 'their', 'me', 'you', 'he', 'she',
      'we', 'they', 'do', 'does', 'did', 'can', 'could', 'will', 'would',
      'should', 'may', 'might', 'about', 'from', 'by', 'as', 'if', 'then',
      'no', 'yes', 'not', 'so', 'up', 'out', 'be', 'has', 'have', 'had',
    },
    VoiceLanguage.russian: {
      'и', 'в', 'во', 'на', 'с', 'со', 'у', 'а', 'но', 'о', 'об',
      'это', 'этого', 'этом', 'эта', 'эти', 'для', 'про', 'не',
      'ещё', 'еще', 'какой', 'какая', 'какое', 'какие', 'какого',
      'мой', 'твой', 'его', 'её', 'ее', 'наш', 'ваш', 'их',
      'меня', 'мне', 'тебя', 'тебе', 'ему', 'ей',
      'нас', 'нам', 'вас', 'вам', 'них', 'ним',
      'я', 'ты', 'он', 'она', 'оно', 'мы', 'вы', 'они',
      'к', 'ко', 'от', 'ото', 'за', 'над', 'под', 'перед',
      'между', 'через', 'после', 'около', 'возле', 'мимо',
      'без', 'до', 'из', 'изо', 'сквозь',
      'б', 'бы', 'же', 'ли', 'ль', 'ни', 'что', 'чтобы',
      'который', 'которая', 'которое', 'которые', 'которого',
    },
    VoiceLanguage.spanish: {
      'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
      'y', 'e', 'o', 'u', 'pero', 'sino', 'es', 'está', 'son',
      'este', 'esta', 'estos', 'estas', 'ese', 'esa', 'esos', 'esas',
      'aquel', 'aquella', 'aquellos', 'aquellas',
      'en', 'de', 'del', 'al', 'por', 'para', 'con', 'sin',
      'mi', 'tu', 'su', 'se', 'le', 'lo',
      'yo', 'tú', 'él', 'ella', 'nosotros', 'vosotros', 'ellos', 'ellas',
      'qué', 'cómo', 'cuándo', 'dónde', 'por qué',
      'no', 'sí', 'también', 'muy', 'más', 'menos',
      'ser', 'estar', 'haber', 'tener', 'hacer',
    },
    VoiceLanguage.portuguese: {
      'o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas',
      'e', 'ou', 'mas', 'é', 'são', 'está', 'estão',
      'este', 'esta', 'estes', 'estas', 'esse', 'essa', 'esses', 'essas',
      'aquele', 'aquela', 'aqueles', 'aquelas',
      'em', 'no', 'na', 'nos', 'nas', 'de', 'da', 'do', 'dos', 'das',
      'para', 'por', 'com', 'sem', 'entre',
      'meu', 'minha', 'teu', 'tua', 'seu', 'sua', 'nosso', 'nossa',
      'eu', 'tu', 'ele', 'ela', 'nós', 'vós', 'eles', 'elas',
      'não', 'sim', 'muito', 'mais', 'menos',
      'que', 'como', 'quando', 'onde', 'porque',
    },
    VoiceLanguage.turkish: {
      'bir', 've', 'veya', 'ama', 'fakat', 'ile', 'için', 'gibi',
      'bu', 'şu', 'o', 'bunlar', 'şunlar', 'onlar',
      'ben', 'sen', 'biz', 'siz',
      'benim', 'senin', 'onun', 'bizim', 'sizin', 'onların',
      'de', 'da', 'mi', 'mu', 'mü', 'mı',
      'ne', 'nasıl', 'neden', 'nerede', 'hangi',
      'evet', 'hayır', 'çok', 'daha', 'az',
      'olmak', 'var', 'yok', 'değil',
      'ise', 'iken', 'ki', 'üzere', 'kadar',
    },
    VoiceLanguage.french: {
      'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'de la',
      'et', 'ou', 'mais', 'donc', 'car', 'ni', 'est', 'sont',
      'ce', 'cet', 'cette', 'ces', 'mon', 'ton', 'son',
      'ma', 'ta', 'sa', 'mes', 'tes', 'ses', 'nos', 'vos', 'leurs',
      'je', 'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles',
      'me', 'te', 'se', 'lui', 'leur',
      'en', 'dans', 'sur', 'sous', 'entre', 'par', 'pour', 'avec', 'sans',
      'ne', 'pas', 'plus', 'très', 'trop', 'peu',
      'que', 'qui', 'quoi', 'quel', 'quelle', 'quels', 'quelles',
    },
    VoiceLanguage.chinese: {
      '的', '了', '在', '是', '有', '和', '就', '不', '人', '都', '一',
      '一个', '上', '也', '很', '到', '说', '要', '去', '你', '会',
      '着', '没有', '看', '好', '自己', '这', '他', '她', '它',
      '们', '那', '我', '我们', '你们', '他们', '她们', '它们',
      '什么', '怎么', '为什么', '哪些', '哪个', '谁',
      '吗', '呢', '啊', '吧', '嗯', '哦', '喂',
      '请', '可以', '能', '应该', '可能',
      '还', '再', '又', '才', '刚',
    },
    VoiceLanguage.arabic: {
      'في', 'من', 'إلى', 'عن', 'على', 'مع', 'بين', 'تحت', 'فوق',
      'هو', 'هي', 'هم', 'هن', 'أنا', 'نحن', 'أنت', 'أنتم', 'أنتن',
      'كان', 'كانت', 'كانوا', 'يكون', 'ليست', 'ليس',
      'و', 'أو', 'ثم', 'لكن', 'بل', 'لا', 'لم', 'لن',
      'هذا', 'هذه', 'هؤلاء', 'ذلك', 'تلك', 'أولئك',
      'ماذا', 'لماذا', 'أين', 'كيف', 'متى', 'هل',
      'نعم', 'ربما', 'فقط', 'أيضاً',
      'قد', 'سوف', 'يكونون',
    },
    VoiceLanguage.japanese: {
      'は', 'が', 'を', 'に', 'へ', 'で', 'と', 'から', 'まで', 'より',
      'の', 'も', 'か', 'よ', 'ね', 'な', 'わ', 'さ', 'ぜ', 'ぞ',
      'です', 'ます', 'した', 'いる', 'ある', 'なる',
      'この', 'その', 'あの', 'どの',
      '私', 'あなた', '彼', '彼女', 'それ',
      '何', 'なぜ', 'どこ', 'いつ', 'どのように',
      'はい', 'いいえ', 'とても', 'また',
      'ない', 'ず', 'ぬ', 'ん',
    },
    VoiceLanguage.hindi: {
      'का', 'के', 'की', 'को', 'से', 'में', 'पर', 'तक', 'के लिए',
      'और', 'या', 'लेकिन', 'इसलिए', 'अगर', 'तो',
      'यह', 'ये', 'वह', 'वे', 'उस', 'इन', 'उन',
      'मैं', 'तुम', 'आप', 'हम',
      'मेरा', 'तेरा', 'उसका', 'हमारा', 'आपका',
      'है', 'हैं', 'हूँ', 'हो', 'था', 'थे', 'थी',
      'नहीं', 'हाँ', 'भी', 'ही',
      'क्या', 'क्यों', 'कहाँ', 'कैसे', 'कौन', 'कितना',
    },
    VoiceLanguage.bengal: {
      'এর', 'এবং', 'কিংবা', 'অথবা', 'কিন্তু', 'তবে', 'অতএব',
      'এটি', 'এটা', 'ওটি', 'সেটি', 'সেটা', 'এই', 'ওই', 'সেই',
      'আমি', 'তুমি', 'আপনি', 'সে', 'আমরা', 'তারা',
      'আমার', 'তোমার', 'আপনার', 'তার', 'আমাদের', 'তাদের',
      'আছে', 'ছিল', 'ছিলেন', 'হয়', 'হয়', 'না',
      'বলে', 'করে', 'হয়ে', 'পরে',
      'কি', 'কেন', 'কোথায়', 'কিভাবে', 'কে', 'কত',
      'হ্যাঁ', 'ও', 'খুব', 'আরও',
    },
    VoiceLanguage.german: {
      'der', 'die', 'das', 'dem', 'den', 'des', 'ein', 'eine', 'einer',
      'eines', 'einem', 'einen',
      'und', 'oder', 'aber', 'denn', 'sondern', 'doch', 'ist', 'sind',
      'dieser', 'diese', 'dieses', 'diesem', 'diesen',
      'mein', 'dein', 'sein', 'ihr', 'unser', 'euer',
      'ich', 'du', 'er', 'sie', 'es', 'wir', 'Sie',
      'mich', 'dich', 'sich', 'uns', 'euch',
      'in', 'im', 'an', 'am', 'auf', 'mit', 'von', 'vom', 'zu', 'zum',
      'nach', 'bei', 'aus', 'durch', 'für', 'gegen', 'um',
      'nicht', 'ja', 'nein', 'sehr', 'auch', 'nur', 'schon',
      'wie', 'was', 'wer', 'wem', 'wen', 'wann', 'wo', 'warum',
    },
    VoiceLanguage.korean: {
      '은', '는', '이', '가', '을', '를', '의', '에', '에서',
      '으로', '로', '과', '와', '하고', '부터', '까지',
      '도', '만', '마저', '조차', '커녕',
      '그', '저', '이것', '그것', '저것',
      '나', '너', '당신', '그녀', '우리', '그들',
      '내', '제', '네', '너의', '그의', '그녀의', '우리의',
      '이다', '아니다', '있다', '없다', '하다',
      '아니요', '예', '매우', '정말', '너무',
      '무엇', '누구', '어디', '언제', '왜', '어떻게', '얼마',
    },
    VoiceLanguage.italian: {
      'il', 'lo', 'la', 'i', 'gli', 'le', 'un', 'una', 'un\'',
      'e', 'o', 'ma', 'però', 'dunque', 'quindi', 'è', 'sono',
      'questo', 'questa', 'questi', 'queste', 'quello', 'quella',
      'mio', 'tuo', 'suo', 'nostro', 'vostro', 'loro',
      'io', 'tu', 'lui', 'lei', 'noi', 'voi',
      'mi', 'ti', 'si', 'ci', 'vi',
      'a', 'in', 'da', 'di', 'con', 'su', 'per', 'tra', 'fra',
      'non', 'sì', 'molto', 'più', 'meno', 'anche',
      'che', 'cosa', 'chi', 'dove', 'quando', 'come', 'perché',
    },
    VoiceLanguage.vietnamese: {
      'của', 'và', 'hoặc', 'hay', 'nhưng', 'nếu', 'thì', 'là',
      'này', 'kia', 'ấy', 'đó', 'nào',
      'tôi', 'bạn', 'anh', 'chị', 'em', 'cô', 'chú', 'bác',
      'ông', 'bà', 'họ', 'chúng tôi', 'các bạn', 'chúng ta',
      'của tôi', 'của bạn', 'của anh', 'của chị',
      'có', 'không', 'phải', 'được', 'bị',
      'ở', 'trong', 'trên', 'dưới', 'tại', 'với', 'không có',
      'vâng', 'dạ', 'ừ', 'rất', 'lắm', 'quá', 'hơi',
      'gì', 'đâu', 'sao', 'thế nào', 'bao nhiêu', 'mấy',
    },
  };
}
