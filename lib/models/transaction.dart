// lib/models/transaction.dart

class AppTransaction {
  final int? id;
  final String transactionId;
  final int accountId;
  final double amount;
  final DateTime date;
  final String? description;
  final String category;
  final bool isFixed;
  final String? merchantHandle;
  final String? frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final bool isRecurring;
  final int? parentId;

  AppTransaction({
    this.id,
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.date,
    this.description,
    this.category = 'Uncategorized',
    this.isFixed = false,
    this.merchantHandle,
    this.frequency,
    this.isRecurring = false,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'account_id': accountId,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'category': category,
      'is_fixed': isFixed ? 1 : 0,
      'merchant_handle': merchantHandle,
      'frequency': frequency,
      'is_recurring': isRecurring ? 1 : 0,
      'parent_id': parentId,
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
      category: map['category'] as String? ?? 'Uncategorized',
      isFixed: (map['is_fixed'] as int? ?? 0) == 1,
      merchantHandle: map['merchant_handle'] as String?,
      frequency: map['frequency'] as String?,
      isRecurring: (map['is_recurring'] as int? ?? 0) == 1,
      parentId: map['parent_id'] as int?,
    );
  }
}