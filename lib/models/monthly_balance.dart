class MonthlyBalance {
  final int? id;
  final DateTime date; // Usually the first or last day of the month
  final double assetValue;
  final double liabilityValue;
  final double netWorth;

  MonthlyBalance({
    this.id,
    required this.date,
    required this.assetValue,
    required this.liabilityValue,
    required this.netWorth,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'asset_value': assetValue,
      'liability_value': liabilityValue,
      'net_worth': netWorth,
    };
  }

  factory MonthlyBalance.fromMap(Map<String, dynamic> map) {
    return MonthlyBalance(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      assetValue: map['asset_value'] as double,
      liabilityValue: map['liability_value'] as double,
      netWorth: map['net_worth'] as double,
    );
  }
}
