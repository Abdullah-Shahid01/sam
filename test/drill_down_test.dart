
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/services/database_service.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/models/account.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Testing Drill-Down Filtering Logic...');
  
  DatabaseService.setDatabaseName('test_drill_down.db');
  
  // Clean up DB
  final dbPath = join(await getDatabasesPath(), 'test_drill_down.db');
  if (await databaseFactory.databaseExists(dbPath)) {
    await databaseFactory.deleteDatabase(dbPath);
  }

  final dbService = DatabaseService();
  
  try {
    // Setup Data
    final account = Account(name: 'Test Bank', type: AccountType.asset, balance: 1000);
    final accountId = await dbService.insertAccount(account);

    // Create mixed transactions
    // Food in Jan
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't1', accountId: accountId, amount: -50, date: DateTime(2025, 1, 15), category: 'Food'
    ));
    // Food in Feb
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't2', accountId: accountId, amount: -100, date: DateTime(2025, 2, 10), category: 'Food'
    ));
    // Transport in Feb
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't3', accountId: accountId, amount: -20, date: DateTime(2025, 2, 20), category: 'Transport'
    ));

    // Test 1: Content Filter (Food only)
    print('Test 1: Filter by Category (Food)');
    final foodOnly = await dbService.getTransactions(category: 'Food');
    if (foodOnly.length == 2 && foodOnly.every((t) => t.category == 'Food')) {
       print('✅ SUCCESS: Found 2 Food transactions.');
    } else {
       print('❌ FAILURE: Expected 2 Food transactions, found ${foodOnly.length}.');
       exit(1);
    }

    // Test 2: Date Filter (Feb only)
    print('Test 2: Filter by Date (Feb 1 - Feb 28)');
    final febOnly = await dbService.getTransactions(
      startDate: DateTime(2025, 2, 1),
      endDate: DateTime(2025, 2, 28)
    );
    if (febOnly.length == 2 && febOnly.every((t) => t.date.month == 2)) {
       print('✅ SUCCESS: Found 2 Feb transactions.');
    } else {
       print('❌ FAILURE: Expected 2 Feb transactions, found ${febOnly.length}.');
       exit(1);
    }

    // Test 3: Combined Filter (Food in Feb)
    print('Test 3: Filter by Category AND Date (Food + Feb)');
    final foodInFeb = await dbService.getTransactions(
      startDate: DateTime(2025, 2, 1),
      endDate: DateTime(2025, 2, 28),
      category: 'Food'
    );
    if (foodInFeb.length == 1 && foodInFeb.first.id == 2) { // t2 has ID 2
       print('✅ SUCCESS: Found exactly 1 transaction (Food in Feb).');
    } else {
       print('❌ FAILURE: Expected 1 transaction, found ${foodInFeb.length}.');
       exit(1);
    }

    print('ALL DRILL-DOWN BACKEND TESTS PASSED');

  } catch (e, s) {
    print('❌ ERROR: $e');
    print(s);
    exit(1);
  }
}
