
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

  print('Testing Top Spenders Logic...');
  
  DatabaseService.setDatabaseName('test_top_spenders.db');
  
  // Clean up DB
  final dbPath = join(await getDatabasesPath(), 'test_top_spenders.db');
  if (await databaseFactory.databaseExists(dbPath)) {
    await databaseFactory.deleteDatabase(dbPath);
  }

  final dbService = DatabaseService();
  
  try {
    // Setup Data
    final account = Account(name: 'Test Bank', type: AccountType.asset, balance: 1000);
    final accountId = await dbService.insertAccount(account);

    // Create expenses with different amounts
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't1', accountId: accountId, amount: -10, date: DateTime(2025, 2, 1), category: 'Food'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't2', accountId: accountId, amount: -500, date: DateTime(2025, 2, 5), category: 'Travel'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't3', accountId: accountId, amount: -20, date: DateTime(2025, 2, 10), category: 'Transport'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't4', accountId: accountId, amount: -100, date: DateTime(2025, 2, 15), category: 'Shopping'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't5', accountId: accountId, amount: -5, date: DateTime(2025, 2, 20), category: 'Coffee'
    ));

    // Test 1: Get Top 3 Spenders
    print('Test 1: Get Top 3 Spenders');
    final top3 = await dbService.getTopSpenders(
      DateTime(2025, 2, 1),
      DateTime(2025, 2, 28),
      limit: 3
    );

    if (top3.length != 3) {
      print('❌ FAILURE: Expected 3 items, got ${top3.length}');
      exit(1);
    }
    
    // Check Order (should be -500, -100, -20 if sorting by amount ASC for negative numbers)
    // SQL: ORDER BY amount ASC -> -500, -100, -20, -10, -5
    if (top3[0].amount == -500 && top3[1].amount == -100 && top3[2].amount == -20) {
      print('✅ SUCCESS: Top 3 correct order: ${top3.map((t) => t.amount).toList()}');
    } else {
      print('❌ FAILURE: Incorrect order. Got: ${top3.map((t) => t.amount).toList()}');
      exit(1);
    }

    print('ALL TOP SPENDERS BACKEND TESTS PASSED');

  } catch (e, s) {
    print('❌ ERROR: $e');
    print(s);
    exit(1);
  }
}
