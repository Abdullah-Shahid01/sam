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

  static String _dbName = 'sam_v2.db';

  /// For testing purposes only
  static void setDatabaseName(String name) {
    _dbName = name;
    _database = null; // Reset connection
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);

      return await openDatabase(
        path,
        version: 4,
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
        is_default INTEGER DEFAULT 0,
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
        category TEXT DEFAULT 'Uncategorized',
        is_fixed INTEGER DEFAULT 0,
        merchant_handle TEXT,
        frequency TEXT,
        is_recurring INTEGER DEFAULT 0,
        parent_id INTEGER,
        recurring_day INTEGER,
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

    if (oldVersion < 4) {
      // v4 Migration: recurring day picker + last_interaction support
      await db.execute("ALTER TABLE transactions ADD COLUMN recurring_day INTEGER");
      await db.execute("ALTER TABLE accounts ADD COLUMN last_interaction TEXT");
    }
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

  Future<List<AppTransaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
  }) async {
    final db = await database;
    
    // Construct WHERE clause
    String? whereClause;
    List<dynamic>? whereArgs;

    if (startDate != null || endDate != null || category != null) {
       List<String> conditions = [];
       whereArgs = [];

       if (startDate != null) {
         conditions.add('date >= ?');
         whereArgs.add(startDate.toIso8601String());
       }
       
       if (endDate != null) {
         conditions.add('date <= ?');
         whereArgs.add(endDate.toIso8601String());
       }
       
       if (category != null) {
         conditions.add('category = ?');
         whereArgs.add(category);
       }
       
       whereClause = conditions.join(' AND ');
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
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

  // Default Account Logic

  Future<void> setDefaultAccount(int accountId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing default
      await txn.rawUpdate('UPDATE accounts SET is_default = 0');
      // Set new default
      await txn.rawUpdate('UPDATE accounts SET is_default = 1 WHERE id = ?', [accountId]);
    });
  }

  Future<Account?> getDefaultAccount() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'accounts',
      where: 'is_default = 1',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  Future<void> checkRecurringTransactions() async {
    final db = await database;
    
    // 1. Get all recurring templates
    final List<Map<String, dynamic>> templates = await db.query(
      'transactions',
      where: 'is_recurring = 1',
    );

    for (var templateMap in templates) {
      final template = AppTransaction.fromMap(templateMap);
      if (template.frequency == null || template.frequency == 'None') continue;

      // 2. Find the last generated transaction for this template
      final List<Map<String, dynamic>> lastChild = await db.query(
        'transactions',
        where: 'parent_id = ?',
        whereArgs: [template.id],
        orderBy: 'date DESC',
        limit: 1,
      );

      DateTime lastDate;
      if (lastChild.isNotEmpty) {
        lastDate = DateTime.parse(lastChild.first['date'] as String);
      } else {
        // If no children yet, the "last date" is the template's creation date
        lastDate = template.date;
      }

      // 3. Calculate next due date
      DateTime nextDate = _calculateNextDate(lastDate, template.frequency!, template.recurringDay);
      final now = DateTime.now();

      // 4. Generate transactions if due
      // Use a loop to catch up if multiple periods missed (e.g., user didn't open app for a month)
      // Limit to 12 to prevent infinite loops in case of logic error
      int safeguard = 0;
      while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
        if (safeguard > 12) break; 
        
        final newTx = AppTransaction(
          transactionId: DateTime.now().millisecondsSinceEpoch.toString() + '_$safeguard',
          accountId: template.accountId,
          amount: template.amount,
          date: nextDate,
          description: template.description,
          category: template.category,
          isFixed: template.isFixed,
          merchantHandle: template.merchantHandle,
          parentId: template.id,
          isRecurring: false,
          recurringDay: template.recurringDay,
        );

        await insertTransaction(newTx);
        
        // Advance to next period
        lastDate = nextDate;
        nextDate = _calculateNextDate(lastDate, template.frequency!, template.recurringDay);
        safeguard++;
      }
    }
  }

  DateTime _calculateNextDate(DateTime from, String frequency, [int? recurringDay]) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return from.add(const Duration(days: 1));
      case 'weekly':
        if (recurringDay != null && recurringDay >= 1 && recurringDay <= 7) {
          // recurringDay: 1=Mon, 7=Sun (matches DateTime.monday..sunday)
          int daysUntil = recurringDay - from.weekday;
          if (daysUntil <= 0) daysUntil += 7; // always advance to next week
          return from.add(Duration(days: daysUntil));
        }
        return from.add(const Duration(days: 7));
      case 'monthly':
        final nextMonth = DateTime(from.year, from.month + 1, 1);
        if (recurringDay != null && recurringDay >= 1) {
          // Clamp to last day of the next month
          final lastDayOfMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
          final day = recurringDay > lastDayOfMonth ? lastDayOfMonth : recurringDay;
          return DateTime(nextMonth.year, nextMonth.month, day);
        }
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        if (recurringDay != null && recurringDay >= 1) {
          // recurringDay stores the day-of-month, month comes from template's original date
          return DateTime(from.year + 1, from.month, recurringDay);
        }
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return from.add(const Duration(days: 30)); // Fallback
    }
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
      if (row['total'] != null) {
        if (row['category'] != null) {
           data[row['category'] as String] = (row['total'] as num).toDouble().abs();
        }
      }
    }
    
    return data;
  }

  Future<List<AppTransaction>> getTopSpenders(DateTime start, DateTime end, {int limit = 3}) async {
    final db = await database;
    
    // Amount < 0 for expenses. We want the "largest" expense, which is the most negative number.
    // So order by amount ASC (e.g. -500, -100, -50).
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'date >= ? AND date <= ? AND amount < 0',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'amount ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      return AppTransaction.fromMap(maps[i]);
    });
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