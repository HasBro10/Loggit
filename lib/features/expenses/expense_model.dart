import '../../models/log_entry.dart';

class Expense implements LogEntry {
  @override
  final String category;
  final double amount;
  @override
  final DateTime timestamp;

  Expense({
    required this.category,
    required this.amount,
    required this.timestamp,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      category: json['category'],
      amount: json['amount'].toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String get displayTitle => '$category - £${amount.toStringAsFixed(2)}';

  @override
  String get logType => 'expense';
}
