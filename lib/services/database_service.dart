// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/account.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'sam_v2.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      print('Database initialization error: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        balance REAL NOT NULL,
        last_interaction TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id TEXT NOT NULL,
        account_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');
  }

  Future<int> insertAccount(Account account) async {
    final db = await database;
    final accountWithInteraction = Account(
      id: account.id,
      name: account.name,
      type: account.type,
      balance: account.balance,
      lastInteraction: DateTime.now(),
    );
    return await db.insert('accounts', accountWithInteraction.toMap());
  }

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('accounts');

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<int> updateAccount(Account account) async {
    final db = await database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(int id) async {
    final db = await database;
    
    await db.delete(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [id],
    );
    
    return await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertTransaction(AppTransaction transaction) async {
    final db = await database;
    final result = await db.insert('transactions', transaction.toMap());
    
    await updateAccountBalance(transaction.accountId, transaction.amount);
    
    return result;
  }

  Future<void> updateAccountBalance(int accountId, double amount) async {
    final db = await database;
    
    final account = await db.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [accountId],
    );
    
    if (account.isNotEmpty) {
      final currentBalance = account.first['balance'] as double;
      final newBalance = currentBalance + amount;
      
      await db.update(
        'accounts',
        {
          'balance': newBalance,
          'last_interaction': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
  }

  Future<List<Account>> getRecentAccounts({int limit = 4}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      orderBy: 'last_interaction DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return Account.fromMap(maps[i]);
    });
  }

  Future<List<AppTransaction>> getTransactions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return AppTransaction.fromMap(maps[i]);
    });
  }

  Future<List<AppTransaction>> getTransactionsByAccount(int accountId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return AppTransaction.fromMap(maps[i]);
    });
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}