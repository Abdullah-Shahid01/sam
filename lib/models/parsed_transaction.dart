// lib/models/parsed_transaction.dart

/// Represents a transaction parsed from voice input
class ParsedTransaction {
  final double? amount;
  final String? accountName;
  final bool? isInflow;
  final DateTime? date;
  final String? description;
  final String? category;
  final bool isFixed;
  final double confidence; // 0.0 to 1.0
  final String rawText;

  ParsedTransaction({
    this.amount,
    this.accountName,
    this.isInflow,
    this.date,
    this.description,
    this.category,
    this.isFixed = false,
    required this.confidence,
    required this.rawText,
  });

  bool get isComplete => amount != null && accountName != null && isInflow != null;

  @override
  String toString() {
    return 'ParsedTransaction(amount: $amount, account: $accountName, isInflow: $isInflow, date: $date, category: $category, confidence: $confidence)';
  }
}
