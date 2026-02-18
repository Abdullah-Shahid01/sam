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
        version: 3,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
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
        is_default INTEGER DEFAULT 0
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
        category TEXT DEFAULT 'Uncategorized',
        is_fixed INTEGER DEFAULT 0,
        merchant_handle TEXT,
        frequency TEXT,
        is_recurring INTEGER DEFAULT 0,
        parent_id INTEGER,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE monthly_balances (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        asset_value REAL NOT NULL,
        liability_value REAL NOT NULL,
        net_worth REAL NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE transactions ADD COLUMN category TEXT DEFAULT 'Uncategorized'");
      await db.execute("ALTER TABLE transactions ADD COLUMN is_fixed INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE transactions ADD COLUMN merchant_handle TEXT");
      
      await db.execute('''
        CREATE TABLE monthly_balances (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          asset_value REAL NOT NULL,
          liability_value REAL NOT NULL,
          net_worth REAL NOT NULL
        )
      ''');
    }

    if (oldVersion < 3) {
      // v3 Migration
      await db.execute("ALTER TABLE accounts ADD COLUMN is_default INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE transactions ADD COLUMN frequency TEXT");
      await db.execute("ALTER TABLE transactions ADD COLUMN is_recurring INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE transactions ADD COLUMN parent_id INTEGER");
    }
  }

  Future<int> insertAccount(Account account) async {
    final db = await database;
    return await db.insert('accounts', account.toMap());
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
        {'balance': newBalance},
        where: 'id = ?',
        whereArgs: [accountId],
      );
    }
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

  // Reporting Methods

  Future<Map<String, double>> getExpensesByCategory(DateTime start, DateTime end, {bool excludeFixed = false}) async {
    final db = await database;
    
    String whereClause = 'date >= ? AND date <= ? AND amount < 0';
    List<dynamic> args = [start.toIso8601String(), end.toIso8601String()];

    if (excludeFixed) {
      whereClause += ' AND is_fixed = 0';
    }

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT category, SUM(amount) as total 
      FROM transactions 
      WHERE $whereClause
      GROUP BY category
    ''', args);

    final Map<String, double> data = {};
    for (var row in result) {
      // Amount is negative, so flip it for the chart
      data[row['category'] as String] = (row['total'] as double).abs();
    }
    
    return data;
  }

  Future<Map<String, Map<String, double>>> getTrendData(DateTime start, DateTime end, {String groupBy = 'month'}) async {
    final db = await database;
    
    // SQLite strftime('%Y-%m', date) extracts YYYY-MM
    // %Y-%m-%d for day
    final format = groupBy == 'day' ? '%Y-%m-%d' : '%Y-%m';
    
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        strftime('$format', date) as period,
        SUM(CASE WHEN amount > 0 THEN amount ELSE 0 END) as income,
        SUM(CASE WHEN amount < 0 THEN amount ELSE 0 END) as expense
      FROM transactions
      WHERE date >= ? AND date <= ?
      GROUP BY period
      ORDER BY period ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);

    final Map<String, Map<String, double>> data = {};
    
    for (var row in result) {
      final period = row['period'] as String;
      final label = _formatLabel(period, groupBy);
      data[label] = {
        'income': (row['income'] as num?)?.toDouble() ?? 0.0,
        'expense': (row['expense'] as num?)?.abs().toDouble() ?? 0.0,
      };
    }
    
    return data;
  }
  
  String _formatLabel(String dateStr, String groupBy) {
    // dateStr is either YYYY-MM or YYYY-MM-DD
    try {
      if (groupBy == 'month') {
        final parts = dateStr.split('-');
        final month = int.parse(parts[1]);
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[month - 1];
      } else {
        // Day: Display "DD" or "DD MMM"
        // Let's parse it and return "dd" (e.g., "05", "12") to keep it short for bar chart 
        final date = DateTime.parse(dateStr);
        return '${date.day}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  // Legacy method - kept for backward compatibility if needed, using the new valid range logic
  Future<Map<String, Map<String, double>>> getMonthlyTotals(int months) async {
    final end = DateTime.now();
    final start = DateTime(end.year, end.month - months + 1, 1);
    return getTrendData(start, end, groupBy: 'month');
  }
}