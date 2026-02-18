
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

  print('Initializing Database Service...');
  final dbService = DatabaseService();
  
  // Ensure we start fresh or with existing DB (migration should handle both)
  // For this test, we want to verify the table structure.
  
  try {
    final db = await dbService.database;
    print('Database opened successfully: version ${await db.getVersion()}');
    if (await db.getVersion() != 3) {
      print('❌ FAILURE: Database version mismatch. Expected 3, got ${await db.getVersion()}');
      exit(1);
    }

    // Check if columns exist in transactions table
    final tables = await db.rawQuery("PRAGMA table_info(transactions);");
    final columns = tables.map((r) => r['name'] as String).toSet();
    
    // v3 Checks
    if (columns.contains('frequency') && columns.contains('is_recurring') && columns.contains('parent_id')) {
      print('✅ SUCCESS: New v3 columns found in transactions table.');
    } else {
      print('❌ FAILURE: Missing v3 columns in transactions table. Found: $columns');
      exit(1);
    }

    // Check accounts table for is_default
    final accountTables = await db.rawQuery("PRAGMA table_info(accounts);");
    final accountColumns = accountTables.map((r) => r['name'] as String).toSet();
    if (accountColumns.contains('is_default')) {
      print('✅ SUCCESS: is_default column found in accounts table.');
    } else {
      print('❌ FAILURE: is_default column missing in accounts table.');
      exit(1);
    }

    // Test Data Insertion
    print('Testing data insertion...');
    
    // Create dummy account with isDefault
    final account = Account(
      name: 'Default Test Account', 
      type: AccountType.asset, 
      balance: 1000,
      isDefault: true,
    );
    int accountId = await dbService.insertAccount(account);

    // Insert Recurring Transaction
    final tx = AppTransaction(
      transactionId: 'test_recur_1',
      accountId: accountId,
      amount: 100.0,
      date: DateTime.now(),
      category: 'Rent',
      isFixed: true,
      description: 'Monthly Rent',
      frequency: 'monthly',
      isRecurring: true,
    );
    
    await dbService.insertTransaction(tx);
    
    // Read Comparison
    final savedTxList = await dbService.getTransactions();
    final savedTx = savedTxList.firstWhere((t) => t.transactionId == 'test_recur_1');
    
    if (savedTx.frequency == 'monthly' && savedTx.isRecurring == true) {
      print('✅ SUCCESS: Transaction saved/retrieved with correct Recurring fields.');
    } else {
      print('❌ FAILURE: Transaction data mismatch. Frequency: ${savedTx.frequency}, isRecurring: ${savedTx.isRecurring}');
      exit(1);
    }

    final savedAccounts = await dbService.getAccounts();
    final savedAccount = savedAccounts.firstWhere((a) => a.name == 'Default Test Account');
    if (savedAccount.isDefault == true) {
      print('✅ SUCCESS: Account saved/retrieved with isDefault=true.');
    } else {
      print('❌ FAILURE: Account data mismatch. isDefault: ${savedAccount.isDefault}');
      exit(1);
    }

    print('ALL TESTS PASSED');
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
}
