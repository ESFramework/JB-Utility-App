class HistoryItem {
  final String stockistName;
  final List<Map<String, dynamic>> items;
  final double totalValue;
  final DateTime timestamp;

  HistoryItem({
    required this.stockistName,
    required this.items,
    required this.totalValue,
    required this.timestamp,
  });
}
