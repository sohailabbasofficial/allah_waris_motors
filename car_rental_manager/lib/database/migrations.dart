import 'package:sqflite/sqflite.dart';

import 'tables/customers_table.dart';
import 'tables/payments_table.dart';
import 'tables/settings_table.dart';
import 'tables/transactions_table.dart';

/// Versioned schema migrations for Allah Waris Motors.
///
/// Current version: 6 — clean relational schema:
/// customers ← transactions ← payments, plus settings.
class DatabaseMigrations {
  DatabaseMigrations._();

  static const int latestVersion = 6;

  static Future<void> onCreate(Database db, int version) async {
    await db.execute('PRAGMA foreign_keys = ON');
    await _createV6Schema(db);
    await _seedDefaultSettings(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    await db.execute('PRAGMA foreign_keys = ON');

    if (oldVersion < 2) {
      await _createLegacyV2(db);
    }
    if (oldVersion < 3) {
      await _migrateToV3(db);
    }
    if (oldVersion < 4) {
      await _createLegacyTransactions(db);
    }
    if (oldVersion < 5) {
      await _migratePaymentsToV5(db);
    }
    if (oldVersion < 6) {
      await _migrateToV6(db);
    }
  }

  static Future<void> onDowngrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Safe downgrade: rebuild empty target schema.
    // Callers should warn that data may be lost on downgrade.
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.execute('DROP TABLE IF EXISTS payments');
    await db.execute('DROP TABLE IF EXISTS transactions');
    await db.execute('DROP TABLE IF EXISTS customers');
    await db.execute('DROP TABLE IF EXISTS settings');
    await db.execute('PRAGMA foreign_keys = ON');
    await _createV6Schema(db);
    await _seedDefaultSettings(db);
  }

  static Future<void> _createV6Schema(Database db) async {
    await db.execute(CustomersTable.createSql);
    await db.execute(TransactionsTable.createSql);
    await db.execute(PaymentsTable.createSql);
    await db.execute(SettingsTable.createSql);
    for (final sql in [
      ...CustomersTable.indexes,
      ...TransactionsTable.indexes,
      ...PaymentsTable.indexes,
      ...SettingsTable.indexes,
    ]) {
      await db.execute(sql);
    }
  }

  static Future<void> _seedDefaultSettings(DatabaseExecutor db) async {
    final existing = await db.query(SettingsTable.name, limit: 1);
    if (existing.isNotEmpty) return;
    final now = DateTime.now().toIso8601String();
    await db.insert(SettingsTable.name, {
      SettingsTable.fingerprintEnabled: 0,
      SettingsTable.themeMode: 'light',
      SettingsTable.autoBackupEnabled: 0,
      SettingsTable.backupTime: '21:00',
      SettingsTable.createdAt: now,
      SettingsTable.updatedAt: now,
    });
  }

  static Future<void> _createLegacyV2(Database db) async {
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

  static Future<void> _migrateToV3(Database db) async {
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

  static Future<void> _createLegacyTransactions(Database db) async {
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
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions (date)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_customer_id ON transactions (customer_id)',
    );
  }

  static Future<void> _migratePaymentsToV5(Database db) async {
    final info = await db.rawQuery('PRAGMA table_info(payments)');
    final columns = info.map((row) => row['name'] as String).toSet();
    if (columns.contains('payment_amount') && columns.contains('payment_date')) {
      return;
    }
    if (columns.isEmpty) return;

    await db.execute('ALTER TABLE payments RENAME TO payments_legacy');
    await db.execute('''
      CREATE TABLE payments (
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
    if (columns.contains('amount') && columns.contains('paid_at')) {
      await db.execute('''
        INSERT INTO payments (
          id, customer_id, payment_date, payment_amount,
          remaining_balance, notes, created_at, updated_at
        )
        SELECT
          id, customer_id, paid_at, amount, 0, notes, created_at, created_at
        FROM payments_legacy
      ''');
    }
    await db.execute('DROP TABLE IF EXISTS payments_legacy');
  }

  /// v6: relational schema + settings; payments belong to transactions.
  static Future<void> _migrateToV6(Database db) async {
    await db.execute('PRAGMA foreign_keys = OFF');
    await db.transaction((txn) async {
      // --- customers (drop denormalized financial columns) ---
      await txn.execute('ALTER TABLE customers RENAME TO customers_legacy');
      await txn.execute(CustomersTable.createSql);
      await txn.execute('''
        INSERT INTO customers (id, name, phone, cnic, address, created_at, updated_at)
        SELECT id, name, phone, cnic, address, created_at, updated_at
        FROM customers_legacy
      ''');
      await txn.execute('DROP TABLE customers_legacy');

      // --- transactions: rename date → transaction_date ---
      final txInfo = await txn.rawQuery('PRAGMA table_info(transactions)');
      final txCols = txInfo.map((r) => r['name'] as String).toSet();
      if (txCols.isNotEmpty) {
        await txn.execute('ALTER TABLE transactions RENAME TO transactions_legacy');
        await txn.execute(TransactionsTable.createSql);
        if (txCols.contains('date')) {
          await txn.execute('''
            INSERT INTO transactions (
              id, customer_id, description, total_amount, received_amount,
              remaining_amount, transaction_date, notes, created_at, updated_at
            )
            SELECT
              id, customer_id, description, total_amount, received_amount,
              remaining_amount, date, notes, created_at, updated_at
            FROM transactions_legacy
          ''');
        } else if (txCols.contains('transaction_date')) {
          await txn.execute('''
            INSERT INTO transactions (
              id, customer_id, description, total_amount, received_amount,
              remaining_amount, transaction_date, notes, created_at, updated_at
            )
            SELECT
              id, customer_id, description, total_amount, received_amount,
              remaining_amount, transaction_date, notes, created_at, updated_at
            FROM transactions_legacy
          ''');
        }
        await txn.execute('DROP TABLE transactions_legacy');
      } else {
        await txn.execute(TransactionsTable.createSql);
      }

      // --- payments: customer_id → transaction_id ---
      final payInfo = await txn.rawQuery('PRAGMA table_info(payments)');
      final payCols = payInfo.map((r) => r['name'] as String).toSet();
      if (payCols.contains('customer_id')) {
        await txn.execute('ALTER TABLE payments RENAME TO payments_legacy');
        await txn.execute(PaymentsTable.createSql);

        // Link each legacy payment to the customer's earliest open (or any) transaction.
        final legacy = await txn.query('payments_legacy');
        for (final row in legacy) {
          final customerId = row['customer_id'] as int?;
          if (customerId == null) continue;
          final txs = await txn.query(
            'transactions',
            columns: ['id'],
            where: 'customer_id = ?',
            whereArgs: [customerId],
            orderBy:
                'CASE WHEN remaining_amount > 0 THEN 0 ELSE 1 END, datetime(transaction_date) ASC, id ASC',
            limit: 1,
          );
          int? transactionId = txs.isEmpty ? null : txs.first['id'] as int?;
          if (transactionId == null) {
            final now = DateTime.now().toIso8601String();
            final amount =
                (row['payment_amount'] as num?)?.toDouble() ?? 0;
            transactionId = await txn.insert('transactions', {
              'customer_id': customerId,
              'description': 'Migrated payment adjustment',
              'total_amount': amount,
              'received_amount': 0,
              'remaining_amount': amount,
              'transaction_date':
                  (row['payment_date'] as String?) ?? now,
              'notes': 'Auto-created during schema v6 migration',
              'created_at': now,
              'updated_at': now,
            });
          }
          await txn.insert('payments', {
            'id': row['id'],
            'transaction_id': transactionId,
            'payment_amount': row['payment_amount'],
            'payment_date': row['payment_date'],
            'notes': row['notes'],
            'created_at':
                row['created_at'] ?? DateTime.now().toIso8601String(),
          });
        }
        await txn.execute('DROP TABLE payments_legacy');
      } else if (!payCols.contains('transaction_id')) {
        await txn.execute(PaymentsTable.createSql);
      }

      await txn.execute(SettingsTable.createSql);
      await _seedDefaultSettings(txn);

      for (final sql in [
        ...CustomersTable.indexes,
        ...TransactionsTable.indexes,
        ...PaymentsTable.indexes,
      ]) {
        await txn.execute(sql);
      }

      // Recalculate transaction remaining amounts after payment migration.
      final txs = await txn.query('transactions', columns: ['id', 'total_amount', 'received_amount']);
      for (final tx in txs) {
        final id = tx['id'] as int;
        final total = (tx['total_amount'] as num?)?.toDouble() ?? 0;
        final received = (tx['received_amount'] as num?)?.toDouble() ?? 0;
        final paidRows = await txn.rawQuery(
          'SELECT COALESCE(SUM(payment_amount), 0) AS paid FROM payments WHERE transaction_id = ?',
          [id],
        );
        final paid = (paidRows.first['paid'] as num?)?.toDouble() ?? 0;
        var remaining = total - received - paid;
        if (remaining < 0) remaining = 0;
        await txn.update(
          'transactions',
          {
            'remaining_amount': remaining,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
    await db.execute('PRAGMA foreign_keys = ON');
  }
}
