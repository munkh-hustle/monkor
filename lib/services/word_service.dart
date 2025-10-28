// services/word_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_model.dart';

class WordService {
  Future<WordResponse> loadWords() async {
    // Load from assets or network
    final String jsonString = await rootBundle.loadString('assets/words.json');
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return WordResponse.fromJson(jsonData);
  }
}
