// lib/models/transaction.dart

class AppTransaction {
  final int? id;
  final String transactionId;
  final int accountId;
  final double amount;
  final DateTime date;
  final String? description;

  AppTransaction({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'account_id': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory AppTransaction.fromMap(Map<String, dynamic> map) {
    return AppTransaction(
      id: map['id'] as int?,
      transactionId: map['transaction_id'] as String,
      accountId: map['account_id'] as int,
      amount: map['amount'] as double,
      date: DateTime.parse(map['date'] as String),
      description: map['description'] as String?,
    );
  }
}