import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService {
  static const String _key = 'calculation_history';

  static Future<void> saveHistory(List<HistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson =
        history
            .map(
              (item) => {
                'stockistName': item.stockistName,
                'items': item.items,
                'totalValue': item.totalValue,
                'timestamp': item.timestamp.toIso8601String(),
              },
            )
            .toList();
    await prefs.setString(_key, jsonEncode(historyJson));
  }

  static Future<List<HistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_key);
    if (historyJson == null) return [];

    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded
        .map(
          (item) => HistoryItem(
            stockistName: item['stockistName'],
            items: List<Map<String, dynamic>>.from(item['items']),
            totalValue: item['totalValue'],
            timestamp: DateTime.parse(item['timestamp']),
          ),
        )
        .toList();
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
