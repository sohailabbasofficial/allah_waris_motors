import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/customer_balance_service.dart';
import '../models/transaction_model.dart';
import '../services/transaction_validation_service.dart';

class TransactionNotFoundException implements Exception {
  TransactionNotFoundException(this.id);
  final int id;

  @override
  String toString() => 'Transaction not found: $id';
}

class DatabaseUnavailableException implements Exception {
  @override
  String toString() => 'SQLite is unavailable on this platform.';
}

/// SQLite CRUD for transactions + customer balance sync.
class TransactionRepository {
  TransactionRepository(
    this._helper, {
    CustomerBalanceService balanceService = const CustomerBalanceService(),
  }) : _balanceService = balanceService;

  final DatabaseHelper _helper;
  final CustomerBalanceService _balanceService;

  Future<Database> _db() async {
    final db = await _helper.databaseOrNull;
    if (db == null) throw DatabaseUnavailableException();
    return db;
  }

  Future<List<TransactionModel>> getAll() async {
    final db = await _helper.databaseOrNull;
    if (db == null) return [];
    final rows = await db.rawQuery('''
      SELECT t.*, c.name AS customer_name
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      ORDER BY datetime(t.date) DESC, datetime(t.created_at) DESC
    ''');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<TransactionModel> getById(int id) async {
    final db = await _db();
    final rows = await db.rawQuery(
      '''
      SELECT t.*, c.name AS customer_name
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      WHERE t.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) throw TransactionNotFoundException(id);
    return TransactionModel.fromMap(rows.first);
  }

  Future<TransactionModel> add({
    required int customerId,
    required DateTime date,
    required String description,
    required double totalAmount,
    required double receivedAmount,
    String? notes,
  }) async {
    final db = await _db();
    final remaining = TransactionValidationService.remaining(
      totalAmount,
      receivedAmount,
    );
    final now = DateTime.now();

    final id = await db.insert('transactions', {
      'customer_id': customerId,
      'date': date.toIso8601String(),
      'description': description.trim(),
      'total_amount': totalAmount,
      'received_amount': receivedAmount,
      'remaining_amount': remaining,
      'notes': _nullableTrim(notes),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await _balanceService.syncCustomer(db, customerId);
    return getById(id);
  }

  Future<TransactionModel> update({
    required int id,
    required int customerId,
    required DateTime date,
    required String description,
    required double totalAmount,
    required double receivedAmount,
    String? notes,
  }) async {
    final db = await _db();
    final existing = await getById(id);
    final remaining = TransactionValidationService.remaining(
      totalAmount,
      receivedAmount,
    );

    final updated = await db.update(
      'transactions',
      {
        'customer_id': customerId,
        'date': date.toIso8601String(),
        'description': description.trim(),
        'total_amount': totalAmount,
        'received_amount': receivedAmount,
        'remaining_amount': remaining,
        'notes': _nullableTrim(notes),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) throw TransactionNotFoundException(id);

    await _balanceService.syncCustomer(db, existing.customerId);
    if (existing.customerId != customerId) {
      await _balanceService.syncCustomer(db, customerId);
    }
    return getById(id);
  }

  Future<void> delete(int id) async {
    final db = await _db();
    final existing = await getById(id);
    final deleted = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted == 0) throw TransactionNotFoundException(id);
    await _balanceService.syncCustomer(db, existing.customerId);
  }

  String? _nullableTrim(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
