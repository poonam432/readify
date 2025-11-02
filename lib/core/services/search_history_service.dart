import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static const String _historyKey = 'search_history';
  static const int _maxHistoryItems = 20;

  Future<List<String>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);
      if (historyJson != null) {
        final List<dynamic> history = json.decode(historyJson);
        return history.cast<String>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> addSearchQuery(String query) async {
    try {
      final history = await getSearchHistory();
      history.remove(query);
      history.insert(0, query);
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_historyKey, json.encode(history));
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Handle error silently
    }
  }
}


