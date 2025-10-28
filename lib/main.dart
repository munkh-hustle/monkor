// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'models/word_model.dart';
import 'services/word_service.dart'; // Add this import

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
  int _currentIndex = 0;
  String _currentFile = 'All Files'; // Track current loaded file

  // Add WordService instance
  final WordService _wordService = WordService();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

    Future<void> _loadWords() async {
    try {
      // Use WordService to load merged data
      final wordResponse = await _wordService.loadWords();
      setState(() {
        _words = wordResponse.channel.items;
        _filteredWords = _words;
        _isLoading = false;
        _currentFile = 'All Files (${_words.length} words)';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // New method to load specific file
  Future<void> _loadSpecificFile(String filePath) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final wordResponse = await _wordService.loadWordsFromFile(filePath);
      setState(() {
        _words = wordResponse.channel.items;
        _filteredWords = _words;
        _isLoading = false;
        _currentFile = _getFileName(filePath) + ' (${_words.length} words)';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '파일을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  String _getFileName(String path) {
    return path.split('/').last.split('.').first;
  }

  Future<WordResponse> _loadJsonData() async {
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
      _filteredWords = _words.where((word) {
        final korean = word.wordInfo.orgWord.toLowerCase();
        final hanja = word.wordInfo.orgLanguage.toLowerCase();
        final searchLower = query.toLowerCase();
        return korean.contains(searchLower) || hanja.contains(searchLower);
      }).toList();
    });
  }

  // Get unique collections by part of speech and level
  List<Collection> getCollections() {
    Map<String, Collection> collections = {};
    
    for (var word in _words) {
      final key = '${word.wordInfo.partOfSpeech}-${word.wordInfo.level}';
      if (!collections.containsKey(key)) {
        collections[key] = Collection(
          name: '${word.wordInfo.partOfSpeech} (${word.wordInfo.level})',
          partOfSpeech: word.wordInfo.partOfSpeech,
          level: word.wordInfo.level,
          words: [],
        );
      }
      collections[key]!.words.add(word);
    }
    
    return collections.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('한자-몽골어 사전'),
            Text(
              _currentFile,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          // File selection menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'all') {
                _loadWords(); // Load all files
              } else {
                _loadSpecificFile(value);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'all',
                  child: Text('All Files (Combined)'),
                ),
                PopupMenuItem(
                  value: 'assets/1214752_5994.json',
                  child: Text('File 1: 1214752_5994.json'),
                ),
                PopupMenuItem(
                  value: 'assets/1214752_6176.json',
                  child: Text('File 2: 1214752_6176.json'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _currentIndex == 0
                  ? _buildDictionaryView()
                  : _buildFlashcardView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '사전',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flip),
            label: '플래시카드',
          ),
        ],
      ),
    );
  }

  Widget _buildDictionaryView() {
    return Column(
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

        // Word List
        Expanded(
          child: _filteredWords.isEmpty
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
    );
  }

// Add this to your _buildFlashcardView method
Widget _buildFlashcardView() {
  final collections = getCollections();
  
  return Column(
    children: [
      // File info header
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        color: Colors.blue[50],
        child: Text(
          '현재 파일: $_currentFile',
          style: TextStyle(fontSize: 14, color: Colors.blue[800]),
          textAlign: TextAlign.center,
        ),
      ),
      
      Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          '컬렉션 선택',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      
      // Collection statistics
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatCard('총 단어', _words.length.toString()),
            _buildStatCard('컬렉션', collections.length.toString()),
            _buildStatCard('레벨', _getLevelCount().toString()),
          ],
        ),
      ),
      
      SizedBox(height: 16),
      
      Expanded(
        child: ListView.builder(
          itemCount: collections.length,
          itemBuilder: (context, index) {
            final collection = collections[index];
            return CollectionCard(
              collection: collection,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FlashcardScreen(collection: collection),
                  ),
                );
              },
            );
          },
        ),
      ),
    ],
  );
}

Widget _buildStatCard(String title, String value) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    ),
  );
}

int _getLevelCount() {
  final levels = _words.map((word) => word.wordInfo.level).toSet();
  return levels.length;
}
}

class Collection {
  final String name;
  final String partOfSpeech;
  final String level;
  final List<WordItem> words;

  Collection({
    required this.name,
    required this.partOfSpeech,
    required this.level,
    required this.words,
  });
}

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getColorForPartOfSpeech(collection.partOfSpeech),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.library_books,
            color: Colors.white,
          ),
        ),
        title: Text(
          collection.name,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${collection.words.length}개 단어'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Color _getColorForPartOfSpeech(String partOfSpeech) {
    switch (partOfSpeech) {
      case '명사':
        return Colors.blue;
      case '동사':
        return Colors.green;
      case '형용사':
        return Colors.orange;
      case '부사':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

class FlashcardScreen extends StatefulWidget {
  final Collection collection;

  const FlashcardScreen({super.key, required this.collection});

  @override
  _FlashcardScreenState createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _currentCardIndex = 0;
  bool _showBack = false;
  PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final currentWord = widget.collection.words[_currentCardIndex];
    final firstSense = currentWord.senseInfo.senseDataList.isNotEmpty
        ? currentWord.senseInfo.senseDataList.first
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
        backgroundColor: _getColorForPartOfSpeech(widget.collection.partOfSpeech),
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentCardIndex + 1) / widget.collection.words.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _getColorForPartOfSpeech(widget.collection.partOfSpeech),
            ),
          ),
          SizedBox(height: 16),

          // Card counter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentCardIndex + 1} / ${widget.collection.words.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (widget.collection.words.length > 1)
                  IconButton(
                    icon: Icon(Icons.shuffle),
                    onPressed: _shuffleCards,
                  ),
              ],
            ),
          ),

          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: _showBack ? _buildBackCard(currentWord, firstSense) : _buildFrontCard(currentWord),
                ),
              ),
            ),
          ),

          // Navigation buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _currentCardIndex > 0 ? _previousCard : null,
                  child: Text('이전'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: _flipCard,
                  child: Text(_showBack ? '앞면 보기' : '뒷면 보기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColorForPartOfSpeech(widget.collection.partOfSpeech),
                  ),
                ),
                ElevatedButton(
                  onPressed: _currentCardIndex < widget.collection.words.length - 1 ? _nextCard : null,
                  child: Text('다음'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getColorForPartOfSpeech(widget.collection.partOfSpeech),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontCard(WordItem word) {
    return Card(
      key: ValueKey('front'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              word.wordInfo.orgWord,
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            if (word.wordInfo.orgLanguage.isNotEmpty)
              Text(
                word.wordInfo.orgLanguage,
                style: TextStyle(fontSize: 24, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            SizedBox(height: 8),
            if (word.wordInfo.pronunciation.isNotEmpty)
              Text(
                word.wordInfo.pronunciation,
                style: TextStyle(fontSize: 18, color: Colors.grey[500]),
              ),
            SizedBox(height: 24),
            Text(
              '카드를 탭하여 뜻 보기',
              style: TextStyle(fontSize: 14, color: Colors.grey[400], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackCard(WordItem word, SenseData? sense) {
    return Card(
      key: ValueKey('back'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _getColorForPartOfSpeech(widget.collection.partOfSpeech).withOpacity(0.1),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                word.wordInfo.orgWord,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              if (word.wordInfo.orgLanguage.isNotEmpty)
                Text(
                  word.wordInfo.orgLanguage,
                  style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              SizedBox(height: 24),
              
              // Mongolian translation
              Text(
                sense?.mongolianTranslation ?? '',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Korean definition
              Text(
                sense?.definition ?? '',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Mongolian definition
              if (sense?.mongolianDefinition?.isNotEmpty ?? false)
                Text(
                  sense!.mongolianDefinition,
                  style: TextStyle(fontSize: 14, color: Colors.green[700]),
                  textAlign: TextAlign.center,
                ),
              
              // Examples
              if (sense?.examples?.isNotEmpty ?? false) ...[
                SizedBox(height: 20),
                Text(
                  '예문:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...sense!.examples.take(2).map(
                  (example) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• ${example.example}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _flipCard() {
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _nextCard() {
    setState(() {
      _currentCardIndex = (_currentCardIndex + 1) % widget.collection.words.length;
      _showBack = false;
    });
  }

  void _previousCard() {
    setState(() {
      _currentCardIndex = (_currentCardIndex - 1) % widget.collection.words.length;
      _showBack = false;
    });
  }

  void _shuffleCards() {
    setState(() {
      widget.collection.words.shuffle();
      _currentCardIndex = 0;
      _showBack = false;
    });
  }

  Color _getColorForPartOfSpeech(String partOfSpeech) {
    switch (partOfSpeech) {
      case '명사':
        return Colors.blue;
      case '동사':
        return Colors.green;
      case '형용사':
        return Colors.orange;
      case '부사':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

// Your existing WordCard widget remains the same...
class WordCard extends StatelessWidget {
  final WordItem wordItem;

  const WordCard({super.key, required this.wordItem});

  @override
  Widget build(BuildContext context) {
    final wordInfo = wordItem.wordInfo;
    final firstSense = wordItem.senseInfo.senseDataList.isNotEmpty
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
              ...firstSense.examples.take(2).map(
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