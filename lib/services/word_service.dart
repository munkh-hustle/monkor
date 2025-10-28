// services/word_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/word_model.dart';

class WordService {
  Future<WordResponse> loadWords() async {
    try {
      // Load both JSON files
      final String jsonString1 = await rootBundle.loadString('assets/1214752_5994.json');
      final String jsonString2 = await rootBundle.loadString('assets/1214752_6176.json');
      
      final Map<String, dynamic> jsonData1 = json.decode(jsonString1);
      final Map<String, dynamic> jsonData2 = json.decode(jsonString2);
      
      // Merge the data
      return _mergeWordData(jsonData1, jsonData2);
    } catch (e) {
      throw Exception('Failed to load word data: $e');
    }
  }

  WordResponse _mergeWordData(Map<String, dynamic> data1, Map<String, dynamic> data2) {
    final channel1 = data1['channel'];
    final channel2 = data2['channel'];
    
    // Calculate total items
    final total1 = int.parse(channel1['total'].toString());
    final total2 = int.parse(channel2['total'].toString());
    final total = total1 + total2;
    
    // Combine items
    final List<dynamic> combinedItems = [];
    
    if (channel1['item'] != null && channel1['item'] is List) {
      combinedItems.addAll(channel1['item']);
    }
    
    if (channel2['item'] != null && channel2['item'] is List) {
      combinedItems.addAll(channel2['item']);
    }
    
    // Create merged channel
    final mergedChannel = {
      'total': total,
      'item': combinedItems,
    };
    
    return WordResponse.fromJson({'channel': mergedChannel});
  }

  // Alternative: Load words from specific files if needed separately
  Future<WordResponse> loadWordsFromFile(String filePath) async {
    final String jsonString = await rootBundle.loadString(filePath);
    final Map<String, dynamic> jsonData = json.decode(jsonString);
    return WordResponse.fromJson(jsonData);
  }

  // Get list of available word files
  List<String> getAvailableWordFiles() {
    return [
      'assets/1214752_5994.json',
      'assets/1214752_6176.json',
    ];
  }
}