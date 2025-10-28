// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'models/word_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한자-몽골어 사전',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DictionaryHome(),
    );
  }
}

class DictionaryHome extends StatefulWidget {
  const DictionaryHome({super.key});

  @override
  _DictionaryHomeState createState() => _DictionaryHomeState();
}

class _DictionaryHomeState extends State<DictionaryHome> {
  List<WordItem> _words = [];
  List<WordItem> _filteredWords = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final wordResponse = await _loadJsonData();
      setState(() {
        _words = wordResponse.channel.items;
        _filteredWords = _words;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<WordResponse> _loadJsonData() async {
    // Load JSON from assets
    final String jsonString = await rootBundle.loadString('assets/words.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return WordResponse.fromJson(jsonData);
  }

  void _searchWords(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredWords = _words;
      });
      return;
    }

    setState(() {
      _filteredWords =
          _words.where((word) {
            final korean = word.wordInfo.orgWord.toLowerCase();
            final hanja = word.wordInfo.orgLanguage.toLowerCase();
            final searchLower = query.toLowerCase();

            return korean.contains(searchLower) || hanja.contains(searchLower);
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('한자-몽골어 사전'),
        backgroundColor: Colors.blue[700],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '한국어나 한자로 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _searchWords,
            ),
          ),

          // Result Count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${_filteredWords.length}개 단어',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                if (_searchController.text.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      _searchController.clear();
                      _searchWords('');
                    },
                    child: Text('검색 초기화'),
                  ),
              ],
            ),
          ),

          // Loading/Error/Results
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _filteredWords.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            '검색 결과가 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredWords.length,
                      itemBuilder: (context, index) {
                        return WordCard(wordItem: _filteredWords[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

// Your existing WordCard widget remains the same...
class WordCard extends StatelessWidget {
  final WordItem wordItem;

  const WordCard({super.key, required this.wordItem});

  @override
  Widget build(BuildContext context) {
    final wordInfo = wordItem.wordInfo;
    final firstSense =
        wordItem.senseInfo.senseDataList.isNotEmpty
            ? wordItem.senseInfo.senseDataList.first
            : null;

    if (firstSense == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('데이터를 불러올 수 없습니다'),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Korean word and Hanja
            Row(
              children: [
                Text(
                  wordInfo.orgWord,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                if (wordInfo.orgLanguage.isNotEmpty)
                  Text(
                    '(${wordInfo.orgLanguage})',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
              ],
            ),
            SizedBox(height: 4),

            // Pronunciation
            if (wordInfo.pronunciation.isNotEmpty)
              Text(
                '발음: ${wordInfo.pronunciation}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),

            SizedBox(height: 8),

            // Mongolian translation
            Text(
              firstSense.mongolianTranslation,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),

            SizedBox(height: 4),

            // Korean definition
            Text(firstSense.definition, style: TextStyle(fontSize: 14)),

            // Mongolian definition
            if (firstSense.mongolianDefinition.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  firstSense.mongolianDefinition,
                  style: TextStyle(fontSize: 14, color: Colors.green[700]),
                ),
              ),

            // Examples (show first 2)
            if (firstSense.examples.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                '예문:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              ...firstSense.examples
                  .take(2)
                  .map(
                    (example) => Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        '• ${example.example}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ),
            ],

            // Level and part of speech
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  label: Text(
                    wordInfo.partOfSpeech,
                    style: TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Chip(
                  label: Text(wordInfo.level, style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
