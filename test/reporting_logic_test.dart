
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/models/account.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/services/database_service.dart';
import 'dart:io';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Initializing Database Service for Reporting Test...');
  final dbService = DatabaseService();
  final db = await dbService.database;

  // Clear data for test
  await db.delete('transactions');
  await db.delete('accounts');

  // Setup Data
  final accountId = await dbService.insertAccount(
    Account(name: 'Test Bank', type: AccountType.asset, balance: 10000),
  );

  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1, 15);
  
  // 1. Insert Expenses
  await dbService.insertTransaction(AppTransaction(
    transactionId: '1', accountId: accountId, amount: -50, date: now, category: 'Food', isFixed: false
  ));
  await dbService.insertTransaction(AppTransaction(
    transactionId: '2', accountId: accountId, amount: -100, date: now, category: 'Food', isFixed: false
  ));
  await dbService.insertTransaction(AppTransaction(
    transactionId: '3', accountId: accountId, amount: -500, date: now, category: 'Rent', isFixed: true
  ));
  
  // Last Month Data
  await dbService.insertTransaction(AppTransaction(
    transactionId: '4', accountId: accountId, amount: -200, date: lastMonth, category: 'Food', isFixed: false
  ));
  await dbService.insertTransaction(AppTransaction(
    transactionId: '5', accountId: accountId, amount: 1000, date: lastMonth, category: 'Salary', isFixed: false
  ));

  print('Data inserted.');

  // Test 1: getExpensesByCategory (This Month)
  final expenses = await dbService.getExpensesByCategory(
    DateTime(now.year, now.month, 1),
    now.add(const Duration(days: 1)),
  );
  
  print('Expenses This Month: $expenses');
  
  if (expenses['Food'] == 150.0 && expenses['Rent'] == 500.0) {
    print('✅ SUCCESS: Expense categorization correct.');
  } else {
    print('❌ FAILURE: Expense categorization mismatch.');
    exit(1);
  }

  // Test 2: getExpensesByCategory (Exclude Fixed)
  final expensesNoFixed = await dbService.getExpensesByCategory(
    DateTime(now.year, now.month, 1),
    now.add(const Duration(days: 1)),
    excludeFixed: true,
  );
  
  print('Expenses No Fixed: $expensesNoFixed');
  
  if (expensesNoFixed['Rent'] == null && expensesNoFixed['Food'] == 150.0) {
     print('✅ SUCCESS: Exclude Fixed correct.');
  } else {
    print('❌ FAILURE: Exclude Fixed failed.');
    exit(1);
  }

  // Test 3: getMonthlyTotals
  final monthly = await dbService.getMonthlyTotals(3);
  print('Monthly Totals: $monthly');
  
  // Check Current Month
  // Key format depends on logic, likely "Feb" (if now is Feb)
  // We need to match the format logic we wrote in DatabaseService
  
  // We can just check if values exist in the map values
  bool foundLastMonth = false;
  for (var entry in monthly.entries) {
    if (entry.value['income'] == 1000.0 && entry.value['expense'] == 200.0) {
      foundLastMonth = true;
    }
  }

  if (foundLastMonth) {
    print('✅ SUCCESS: Monthly totals correct.');
  } else {
    print('❌ FAILURE: Monthly totals mismatch.');
    exit(1);
  }

  print('ALL TESTS PASSED');
}
