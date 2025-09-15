import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../models/history_item.dart';
import 'package:intl/intl.dart';
import '../services/history_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HistoryScreen extends StatefulWidget {
  final List<HistoryItem> history;
  final Function()? onClearHistory;

  const HistoryScreen({super.key, required this.history, this.onClearHistory});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _handleClearHistory() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear History'),
            content: const Text('Are you sure you want to clear all history?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onClearHistory?.call();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.primaryColor,
      appBar: AppBar(
        backgroundColor: themeProvider.primaryColor,
        elevation: 0,
        title: Text(
          'History',
          style: TextStyle(color: themeProvider.textColor),
        ),
      ),
      body: Animate(
        effects: [
          ScaleEffect(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOutQuart,
          ),
          FadeEffect(begin: 0.0, end: 1.0, duration: 300.ms),
        ],
        child: Column(
          children: [
            Expanded(
              child:
                  widget.history.isEmpty
                      ? Center(
                        child: Text(
                          'No history available',
                          style: TextStyle(color: themeProvider.textColor),
                        ),
                      )
                      : ListView.builder(
                        itemCount: widget.history.length,
                        itemBuilder: (context, index) {
                          final item = widget.history[index];
                          return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: themeProvider.secondaryColor,
                                child: ExpansionTile(
                                  title: Text(
                                    item.stockistName.isEmpty
                                        ? 'Unnamed Order'
                                        : item.stockistName,
                                    style: TextStyle(
                                      color: themeProvider.textColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${DateFormat('MMM dd, yyyy HH:mm').format(item.timestamp)}\nTotal: ₹${item.totalValue.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: themeProvider.textColorSecondary,
                                    ),
                                  ),
                                  children: [
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: item.items.length,
                                      itemBuilder: (context, idx) {
                                        final product = item.items[idx];
                                        return ListTile(
                                          dense: true,
                                          title: Text(
                                            product['name'] as String,
                                            style: TextStyle(
                                              color: themeProvider.textColor,
                                            ),
                                          ),
                                          trailing: Text(
                                            '${product['strips']} strips - ₹${product['value'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              color: themeProvider.textColor,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                              .slideX(
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutQuart,
                                duration: 400.ms,
                                delay: (50 * index).ms,
                              );
                        },
                      ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          widget.history.isNotEmpty
              ? Container(
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: FloatingActionButton(
                  onPressed: _handleClearHistory,
                  backgroundColor: Colors.red,
                  child: Icon(Icons.delete_outline, color: Colors.white),
                ),
              )
              : null,
    );
  }
}
