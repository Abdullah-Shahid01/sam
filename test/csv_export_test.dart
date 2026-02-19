
import 'package:flutter_test/flutter_test.dart';
import 'package:sam/services/csv_export_service.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/models/account.dart';

void main() {
  test('CSV Generation Test', () {
    final service = CsvExportService();
    
    // Setup Data
    final accounts = [
      Account(id: 1, name: 'Bank', type: AccountType.asset, balance: 100),
      Account(id: 2, name: 'Cash', type: AccountType.asset, balance: 50),
    ];
    
    final transactions = [
      AppTransaction(
        transactionId: '1',
        accountId: 1,
        amount: -10.50,
        date: DateTime(2025, 1, 1, 12, 0),
        category: 'Food',
        description: 'Lunch at Joe\'s',
      ),
      AppTransaction(
        transactionId: '2',
        accountId: 2,
        amount: 500.00,
        date: DateTime(2025, 1, 2, 9, 30),
        category: 'Salary',
        description: 'Monthly Salary',
      ),
       AppTransaction(
        transactionId: '3',
        accountId: 1,
        amount: -5.00,
        date: DateTime(2025, 1, 3, 15, 45),
        category: 'Transport',
        description: 'Bus, Ticket', // Has comma, needs escaping
      ),
    ];

    print('Generating CSV...');
    final csv = service.generateCsv(transactions, accounts: accounts);
    print(csv);

    // Verify Header
    expect(csv.contains('Date,Amount,Category,Description,Account,Type'), true);

    // Verify Row 1
    expect(csv.contains('2025-01-01 12:00,-10.50,Food,Lunch at Joe\'s,Bank,Expense'), true);

    // Verify Row 2
    expect(csv.contains('2025-01-02 09:30,500.00,Salary,Monthly Salary,Cash,Income'), true);
    
    // Verify Escaping (Transaction 3)
    // "Bus, Ticket" should be quoted
    expect(csv.contains('"Bus, Ticket"'), true);
    
    print('✅ CSV Generation Verified');
  });
}
