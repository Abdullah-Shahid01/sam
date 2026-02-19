
import 'package:flutter_test/flutter_test.dart';
import 'package:sam/services/transaction_parser.dart';
import 'package:sam/models/account.dart';

void main() {
  group('Validation Polish Tests', () {
    final parser = TransactionParser();
    final accounts = [Account(name: 'Cash', type: AccountType.asset, balance: 0)];

    test('Parser extracts categories correctly', () {
      final inputs = {
        'Lunch 50': 'Food',
        'Uber to work 30': 'Transport',
        'Paid DEWA bill 500': 'Utilities',
        'Netflix subscription': 'Entertainment',
        'New running shoes': 'Shopping',
        'Salary received': 'Salary',
        'Random thing 50': 'Uncategorized', // Default
      };

      inputs.forEach((text, expectedCategory) {
        final result = parser.parse(text, accounts);
        expect(result.category, equals(expectedCategory), reason: 'Failed for input: "$text"');
      });
    });

    test('Parser sets isFixed for Rent and Utilities', () {
      final rentResult = parser.parse('Rent payment 5000', accounts);
      expect(rentResult.category, equals('Rent'));
      expect(rentResult.isFixed, isTrue);

      final utilResult = parser.parse('Electricity bill 200', accounts);
      expect(utilResult.category, equals('Utilities'));
      expect(utilResult.isFixed, isTrue);

      final foodResult = parser.parse('Burger 50', accounts);
      expect(foodResult.category, equals('Food'));
      expect(foodResult.isFixed, isFalse);
    });

    test('Parser handles zero or negative amounts implicitly (parser returns null or positive)', () {
       // The parser logic `_extractAmount` checks for value > 0.
       // So "Spend 0" should return amount null?
       final zeroResult = parser.parse('Spend 0 on nothing', accounts);
       expect(zeroResult.amount, isNull);

       final negativeResult = parser.parse('Spend -50', accounts);
       // Regex might pick up 50. 
       // `_extractAmount` uses regex `\d+`. It ignores sign usually unless handled.
       // Let's see if it picks up 50.
       expect(negativeResult.amount, equals(50.0)); 
       // Because regex sees "50". 
       // The parser doesn't handle negative numbers in text yet, it assumes absolute value and uses "inflow/outflow" keywords.
    });
  });
}
