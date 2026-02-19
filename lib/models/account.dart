// lib/models/account.dart

enum AccountType {
  asset,
  liability;

  String get displayName {
    switch (this) {
      case AccountType.asset:
        return 'Asset';
      case AccountType.liability:
        return 'Liability';
    }
  }
}

class Account {
  final int? id;
  final String name;
  final AccountType type;
  final double balance;
  final DateTime? lastInteraction;

  Account({
    this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.lastInteraction,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'balance': balance,
      'last_interaction': lastInteraction?.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: AccountType.values[map['type'] as int],
      balance: map['balance'] as double,
      lastInteraction: map['last_interaction'] != null 
          ? DateTime.parse(map['last_interaction'] as String)
          : null,
    );
  }
}