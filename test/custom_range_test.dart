
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/services/database_service.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/models/account.dart';
import 'dart:io';
import 'package:path/path.dart';


import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/services/database_service.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/models/account.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() {
  late DatabaseService dbService;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    DatabaseService.setDatabaseName('test_custom_range.db');
    final dbPath = join(await getDatabasesPath(), 'test_custom_range.db');
    if (await databaseFactory.databaseExists(dbPath)) {
      await databaseFactory.deleteDatabase(dbPath);
    }
    
    dbService = DatabaseService();

    // Setup Data
    final account = Account(name: 'Test Bank', type: AccountType.asset, balance: 1000);
    final accountId = await dbService.insertAccount(account);

    // Create transactions in different months
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't1', accountId: accountId, amount: -50, date: DateTime(2025, 1, 15), category: 'Food'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't2', accountId: accountId, amount: -100, date: DateTime(2025, 2, 10), category: 'Food'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't3', accountId: accountId, amount: -20, date: DateTime(2025, 2, 20), category: 'Transport'
    ));
    await dbService.insertTransaction(AppTransaction(
      transactionId: 't4', accountId: accountId, amount: -200, date: DateTime(2025, 3, 5), category: 'Rent'
    ));
  });

  test('Standard Month Range (Feb 1 - Feb 28)', () async {
    final febRangeExpenses = await dbService.getExpensesByCategory(
      DateTime(2025, 2, 1), DateTime(2025, 2, 28)
    );
    // Food: 100, Transport: 20
    expect(febRangeExpenses['Food'], 100.0);
    expect(febRangeExpenses['Transport'], 20.0);
    expect(febRangeExpenses.containsKey('Rent'), false);
  });

  test('Cross-Month Range (Jan 10 - Feb 15)', () async {
    final customRangeExpenses = await dbService.getExpensesByCategory(
      DateTime(2025, 1, 10), DateTime(2025, 2, 15)
    );
    // Food: 50 (Jan) + 100 (Feb) = 150. Transport (Feb 20) is excluded.
    expect(customRangeExpenses['Food'], 150.0);
    expect(customRangeExpenses.containsKey('Transport'), false);
  });

  test('Daily Trend for Custom Range (Jan 10 - Feb 15)', () async {
    final trendData = await dbService.getTrendData(
      DateTime(2025, 1, 10), DateTime(2025, 2, 15), groupBy: 'day'
    );
    
    // Check keys exist (Implementation returns day number strings e.g. "15", "10")
    expect(trendData.containsKey('15'), true);
    expect(trendData.containsKey('10'), true);
    
    // Check amounts
    expect(trendData['15']!['expense'], 50.0);
    expect(trendData['10']!['expense'], 100.0);
  });
}

