
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sam/services/database_service.dart';
import 'package:sam/services/transaction_parser.dart';
import 'package:sam/models/account.dart';
import 'dart:io';

void main() async {
  // Initialize FFI
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('Testing Default Account Logic...');
  final dbService = DatabaseService();
  
  try {
    // 1. Setup Data
    print('1. Setting up accounts...');
    
    // Create two accounts
    final acc1 = Account(name: 'Bank', type: AccountType.asset, balance: 1000);
    final acc2 = Account(name: 'Cash', type: AccountType.asset, balance: 500);
    
    int id1 = await dbService.insertAccount(acc1);
    int id2 = await dbService.insertAccount(acc2);
    
    // 2. Test setDefaultAccount
    print('2. Testing setDefaultAccount...');
    
    // Set Account 1 as default
    await dbService.setDefaultAccount(id1);
    
    var defaultAcc = await dbService.getDefaultAccount();
    if (defaultAcc?.id == id1 && defaultAcc?.isDefault == true) {
      print('✅ SUCCESS: Account 1 set as default.');
    } else {
      print('❌ FAILURE: Failed to set Account 1 as default. Got: ${defaultAcc?.name}');
      exit(1);
    }
    
    // Switch default to Account 2
    await dbService.setDefaultAccount(id2);
    
    defaultAcc = await dbService.getDefaultAccount();
    final allAccs = await dbService.getAccounts();
    final checkAcc1 = allAccs.firstWhere((a) => a.id == id1);
    
    if (defaultAcc?.id == id2 && defaultAcc?.isDefault == true && checkAcc1.isDefault == false) {
      print('✅ SUCCESS: Default switched to Account 2. Account 1 is no longer default.');
    } else {
      print('❌ FAILURE: Failed to switch default. Acc2 Default: ${defaultAcc?.isDefault}, Acc1 Default: ${checkAcc1.isDefault}');
      exit(1);
    }

    // 3. Test TransactionParser fallback
    print('3. Testing TransactionParser fallback...');
    final parser = TransactionParser();
    final accounts = await dbService.getAccounts();
    final defaultAccount = await dbService.getDefaultAccount(); // Should be 'Cash' (id2)
    
    // Case A: Explicit Account Name
    final parsedExplicit = parser.parse("Spent 50 from Bank", accounts, defaultAccount: defaultAccount);
    if (parsedExplicit.accountName == 'Bank') {
      print('✅ SUCCESS: Parser respected explicit account name "Bank".');
    } else {
      print('❌ FAILURE: Parser failed explicit account match. Got: ${parsedExplicit.accountName}');
      exit(1);
    }
    
    // Case B: No Account Name (Fallback)
    final parsedImplicit = parser.parse("Spent 50 on Lunch", accounts, defaultAccount: defaultAccount);
    if (parsedImplicit.accountName == 'Cash') {
      print('✅ SUCCESS: Parser fell back to default account "Cash".');
    } else {
      print('❌ FAILURE: Parser failed fallback. Got: ${parsedImplicit.accountName}, Expected: Cash');
      exit(1);
    }
    
    // Case C: No Default available (should be null)
    final parsedNoDefault = parser.parse("Spent 50 on Lunch", accounts, defaultAccount: null);
    if (parsedNoDefault.accountName == null) {
      print('✅ SUCCESS: Parser correctly returned null account when no default provided.');
    } else {
      print('❌ FAILURE: Parser returned account unexpectedly. Got: ${parsedNoDefault.accountName}');
      exit(1);
    }

    print('ALL DEFAULT ACCOUNT TESTS PASSED');
    
  } catch (e) {
    print('❌ ERROR: $e');
    exit(1);
  }
}
