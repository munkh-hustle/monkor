// models/word_model.dart
class WordResponse {
  final Channel channel;

  WordResponse({required this.channel});

  factory WordResponse.fromJson(Map<String, dynamic> json) {
    return WordResponse(channel: Channel.fromJson(json['channel']));
  }
}

class Channel {
  final int total;
  final List<WordItem> items;

  Channel({required this.total, required this.items});

  factory Channel.fromJson(Map<String, dynamic> json) {
    var items = json['item'] as List;
    return Channel(
      total: int.parse(json['total'].toString()), // Fixed: use toString()
      items: items.map((item) => WordItem.fromJson(item)).toList(),
    );
  }
}

class WordItem {
  final WordInfo wordInfo;
  final SenseInfo senseInfo;

  WordItem({required this.wordInfo, required this.senseInfo});

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      wordInfo: WordInfo.fromJson(json['wordInfo']),
      senseInfo: SenseInfo.fromJson(json['senseInfo']),
    );
  }
}

class WordInfo {
  final String orgWord;
  final String orgLanguage;
  final String pronunciation;
  final String partOfSpeech;
  final String level;
  final String? soundUrl;

  WordInfo({
    required this.orgWord,
    required this.orgLanguage,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.level,
    this.soundUrl,
  });

  factory WordInfo.fromJson(Map<String, dynamic> json) {
    // Handle pronunList safely
    String pronunciation = '';
    String? soundUrl;

    if (json['pronunList'] != null && json['pronunList'] is List) {
      if (json['pronunList'].isNotEmpty) {
        var pronun = json['pronunList'][0];
        if (pronun is Map<String, dynamic>) {
          pronunciation = pronun['pronunciation']?.toString() ?? '';
          soundUrl = pronun['sound']?.toString();
        }
      }
    }

    return WordInfo(
      orgWord: json['org_word']?.toString() ?? '',
      orgLanguage: json['org_language']?.toString() ?? '',
      pronunciation: pronunciation,
      partOfSpeech: json['sp_code_name']?.toString() ?? '',
      level: json['im_cnt']?.toString() ?? '',
      soundUrl: soundUrl,
    );
  }
}

class SenseInfo {
  final List<SenseData> senseDataList;

  SenseInfo({required this.senseDataList});

  factory SenseInfo.fromJson(Map<String, dynamic> json) {
    List<SenseData> senseDataList = [];
    if (json['senseDataList'] != null && json['senseDataList'] is List) {
      senseDataList =
          (json['senseDataList'] as List)
              .map((data) => SenseData.fromJson(data))
              .toList();
    }
    return SenseInfo(senseDataList: senseDataList);
  }
}

class SenseData {
  final String definition;
  final List<Multilan> translations;
  final List<Example> examples;

  SenseData({
    required this.definition,
    required this.translations,
    required this.examples,
  });

  factory SenseData.fromJson(Map<String, dynamic> json) {
    // Get translations
    List<Multilan> translations = [];
    if (json['multilanList'] != null && json['multilanList'] is List) {
      translations =
          (json['multilanList'] as List)
              .map((item) => Multilan.fromJson(item))
              .where((multilan) => multilan.language == '몽골어')
              .toList();
    }

    // Get examples - FIXED VERSION
    List<Example> examples = [];
    if (json['examList'] != null && json['examList'] is Map) {
      var examList = json['examList'];

      // Check each examList type
      for (var key in ['examList1', 'examList2', 'examList3', 'examList4']) {
        if (examList[key] != null && examList[key] is List) {
          for (var exam in examList[key]) {
            if (exam is Map<String, dynamic>) {
              examples.add(Example.fromJson(exam));
            }
          }
        }
      }
    }

    return SenseData(
      definition: json['definition']?.toString() ?? '',
      translations: translations,
      examples: examples,
    );
  }

  String get mongolianTranslation {
    try {
      var mongolian = translations.firstWhere((item) => item.language == '몽골어');
      return mongolian.translation;
    } catch (e) {
      return '';
    }
  }

  String get mongolianDefinition {
    try {
      var mongolian = translations.firstWhere((item) => item.language == '몽골어');
      return mongolian.definition;
    } catch (e) {
      return '';
    }
  }
}

class Multilan {
  final String translation;
  final String definition;
  final String language;

  Multilan({
    required this.translation,
    required this.definition,
    required this.language,
  });

  factory Multilan.fromJson(Map<String, dynamic> json) {
    return Multilan(
      translation: json['multi_translation']?.toString() ?? '',
      definition: json['multi_definition']?.toString() ?? '',
      language: json['nation_code_name']?.toString() ?? '',
    );
  }
}

class Example {
  final String type;
  final String example;

  Example({required this.type, required this.example});

  factory Example.fromJson(Map<String, dynamic> json) {
    return Example(
      type: json['exa_type']?.toString() ?? '문장',
      example: json['example']?.toString() ?? '',
    );
  }
}
