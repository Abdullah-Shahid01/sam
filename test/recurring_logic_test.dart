
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/services/database_service.dart';
import 'package:sam/models/transaction.dart';
import 'package:sam/models/account.dart';
import 'dart:io';
import 'package:path/path.dart';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Testing Recurring Transactions Logic...');
  
  // Clean up DB
  final dbPath = join(await getDatabasesPath(), 'sam_database.db');
  if (await databaseFactory.databaseExists(dbPath)) {
    print('Deleting existing DB at $dbPath');
    await databaseFactory.deleteDatabase(dbPath);
  }

  final dbService = DatabaseService();
  
  try {
    // 1. Setup Account
    print('1. Setting up test account...');
    final account = Account(name: 'Test Bank', type: AccountType.asset, balance: 1000);
    final accountId = await dbService.insertAccount(account);

    // 2. Create a PAST recurring transaction (Monthly, 1 month ago)
    print('2. Creating past recurring transaction...');
    // Date: 35 days ago to ensure it's due
    final pastDate = DateTime.now().subtract(const Duration(days: 35));
    
    final parentTx = AppTransaction(
      transactionId: 'parent_1',
      accountId: accountId,
      amount: -100.0,
      date: pastDate,
      description: 'Netflix Subscription',
      frequency: 'Monthly',
      isRecurring: true,
    );
    
    await dbService.insertTransaction(parentTx);

    // 3. Run checkRecurringTransactions (should generate 1 child)
    print('3. Running checkRecurringTransactions (First Pass)...');
    await dbService.checkRecurringTransactions();

    // Verify child creation
    print('4. verifying child creation (raw)...');
    final db = await dbService.database;
    final allRows = await db.query('transactions');
    
    print('DEBUG: Total rows: ${allRows.length}');
    for (var row in allRows) {
      print('DEBUG: Row: $row');
    }

    // Now try through service
    print('5. verifying via getTransactions...');
    final allTx = await dbService.getTransactions();
    // Should have parent + 1 child
    final children = allTx.where((t) => t.parentId == parentTx.id).toList(); // parentId is int? parentTx.id is String?
    // Wait, parentId in AppTransaction is int?
    // But transactionId is String.
    // In database_service, we use `transactionId` (String).
    // In `AppTransaction`: `final int? parentId;`.
    // Wait. `parentId` should refer to `id` (autoincrement int) OR `transactionId` (String)?
    // `lib/models/transaction.dart`:
    // int? parentId;
    // int? id; // (database id)
    // String transactionId; // (uuid)
    
    // In checkRecurringTransactions:
    // `parentId: template.id` -> template.id is the database ID (int).
    // So `parentId` refers to the database primary key.
    
    // We need to know the database ID of 'parent_1'.
    // `insertTransaction` returns the inserted ID (int).
    // But `insertTransaction` implementation returns the result of `db.insert`.
    // Let's check `insertTransaction` signature in `database_service.dart`.
    // It returns `Future<int>`.
    
    // We didn't capture the result of `insertTransaction(parentTx)`.
    // We can get it from `allRows` where transaction_id = 'parent_1'.
    
    final parentRow = allRows.firstWhere((r) => r['transaction_id'] == 'parent_1');
    final parentDbId = parentRow['id'] as int;
    
    print('DEBUG: Parent DB ID: $parentDbId');
    
    // Check fields of child
    final childRow = allRows.firstWhere((r) => r['parent_id'] == parentDbId, orElse: () => {});
    
    if (childRow.isNotEmpty) {
      print('✅ SUCCESS: Generated 1 child transaction (Row found).');
      
      final childDateStr = childRow['date'] as String;
      final childDate = DateTime.parse(childDateStr);

      if (childDate.isAfter(pastDate)) {
         print('✅ SUCCESS: Child date is after parent date: $childDate');
      } else {
         print('❌ FAILURE: Child date is invalid: $childDate');
         exit(1);
      }
      
      final isRec = childRow['is_recurring'] as int;
      if (isRec == 0) {
         print('✅ SUCCESS: Child is NOT marked as recurring template.');
      } else {
         print('❌ FAILURE: Child should not be recurring (is_recurring=$isRec).');
         exit(1);
      }
      
    } else {
      print('❌ FAILURE: Expected 1 child with parent_id=$parentDbId, found none.');
      exit(1);
    }

    // 4. Run checkRecurringTransactions AGAIN (should generate nothing new)
    print('6. Running checkRecurringTransactions (Second Pass)...');
    await dbService.checkRecurringTransactions();
    
    final allRows2 = await db.query('transactions');
    final childrenCount = allRows2.where((r) => r['parent_id'] == parentDbId).length;
    
    if (childrenCount == 1) {
      print('✅ SUCCESS: No duplicates generated.');
    } else {
      print('❌ FAILURE: Duplicates found! Count: $childrenCount.');
      exit(1);
    }
    
    print('ALL RECURRING LOGIC TESTS PASSED');

  } catch (e, s) {
    print('❌ ERROR: $e');
    print(s);
    exit(1);
  }
}
