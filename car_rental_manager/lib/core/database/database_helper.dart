import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/app_constants.dart';

/// SQLite helper for Allah Waris Motors (versioned schema).
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database?> get databaseOrNull async {
    if (kIsWeb) return null;
    return database;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = p.join(documentsDirectory.path, AppConstants.databaseName);

    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createCustomersTable(db);
    await _createPaymentsTableV5(db);
    await _createTransactionsTable(db);
    await _createIndexes(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCustomersTable(db);
      await _createLegacyPaymentsTable(db);
      await _createIndexes(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _createTransactionsTable(db);
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions (customer_id)',
      );
    }
    if (oldVersion < 5) {
      await _migratePaymentsToV5(db);
    }
  }

  Future<void> _createCustomersTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        cnic TEXT,
        address TEXT,
        total_udhaar REAL NOT NULL DEFAULT 0,
        total_received REAL NOT NULL DEFAULT 0,
        remaining_balance REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createLegacyPaymentsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        notes TEXT,
        paid_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createPaymentsTableV5(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        payment_date TEXT NOT NULL,
        payment_amount REAL NOT NULL,
        remaining_balance REAL NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createTransactionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        total_amount REAL NOT NULL,
        received_amount REAL NOT NULL,
        remaining_amount REAL NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments (customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments (payment_date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_customers_created_at ON customers (created_at)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers (phone)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions (customer_id)',
    );
  }

  Future<void> _migrateToV3(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(customers)');
    final columns = info.map((row) => row['name'] as String).toSet();

    if (!columns.contains('cnic')) {
      await db.execute('ALTER TABLE customers ADD COLUMN cnic TEXT');
    }
    if (!columns.contains('address')) {
      await db.execute('ALTER TABLE customers ADD COLUMN address TEXT');
    }

    await db.execute(
      "UPDATE customers SET phone = 'unknown-' || id WHERE phone IS NULL OR trim(phone) = ''",
    );

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_customers_phone_unique ON customers (phone)',
    );
  }

  /// Rebuilds payments table to Payment Management schema.
  Future<void> _migratePaymentsToV5(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(payments)');
    final columns = info.map((row) => row['name'] as String).toSet();

    // Already on v5 schema.
    if (columns.contains('payment_amount') &&
        columns.contains('payment_date')) {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments (payment_date)',
      );
      return;
    }

    await db.execute('ALTER TABLE payments RENAME TO payments_legacy');
    await _createPaymentsTableV5(db);

    // Migrate legacy rows if the old shape exists.
    if (columns.contains('amount') && columns.contains('paid_at')) {
      await db.execute('''
        INSERT INTO payments (
          id, customer_id, payment_date, payment_amount,
          remaining_balance, notes, created_at, updated_at
        )
        SELECT
          id,
          customer_id,
          paid_at,
          amount,
          0,
          notes,
          created_at,
          created_at
        FROM payments_legacy
      ''');
    }

    await db.execute('DROP TABLE IF EXISTS payments_legacy');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments (customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments (payment_date)',
    );
  }

  /// Absolute path of the SQLite database file (not supported on web).
  Future<String> get databaseFilePath async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, AppConstants.databaseName);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Closes and re-opens the database (used after restore).
  Future<Database> reopen() async {
    await close();
    return database;
  }
}
