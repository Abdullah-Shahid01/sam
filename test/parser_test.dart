
import 'package:flutter_test/flutter_test.dart';
import 'package:sam/services/transaction_parser.dart';
import 'package:sam/models/account.dart';

void main() {
  group('TransactionParser', () {
    final parser = TransactionParser();
    final accounts = [
      Account(id: 1, name: 'Cash', type: AccountType.asset, balance: 1000),
      Account(id: 2, name: 'Bank', type: AccountType.asset, balance: 5000),
    ];

    test('extracts category correctly', () {
      final result1 = parser.parse('Spent 50 on burger', accounts);
      expect(result1.category, 'Food');
      expect(result1.isFixed, false);

      final result2 = parser.parse('Pay 2000 for rent', accounts);
      expect(result2.category, 'Rent');
      expect(result2.isFixed, true); // Rent should be fixed
      
      final result3 = parser.parse('Uber to work cost 40', accounts);
      expect(result3.category, 'Transport');
    });

    test('extracts details correctly with category', () {
      final result = parser.parse('Add 500 salary to bank', accounts);
      expect(result.amount, 500.0);
      expect(result.isInflow, true);
      expect(result.accountName, 'Bank');
      expect(result.category, 'Salary');
    });
    
    test('defaults to Uncategorized', () {
      final result = parser.parse('Spent 100 on mystery item', accounts);
      expect(result.category, 'Uncategorized');
    });
  });
}
