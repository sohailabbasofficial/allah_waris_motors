import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/services/customer_balance_service.dart';
import '../models/payment_model.dart';

class PaymentNotFoundException implements Exception {
  PaymentNotFoundException(this.id);
  final int id;

  @override
  String toString() => 'Payment not found: $id';
}

class PaymentExceedsBalanceException implements Exception {
  PaymentExceedsBalanceException(this.available);
  final double available;

  @override
  String toString() =>
      'Payment exceeds remaining balance (${available.toStringAsFixed(2)})';
}

class DatabaseUnavailableException implements Exception {
  @override
  String toString() => 'SQLite is unavailable on this platform.';
}

class PaymentRepository {
  PaymentRepository(
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

  Future<List<PaymentModel>> getAll({int? customerId}) async {
    final db = await _helper.databaseOrNull;
    if (db == null) return [];

    final rows = customerId == null
        ? await db.rawQuery('''
            SELECT p.*, c.name AS customer_name
            FROM payments p
            INNER JOIN customers c ON c.id = p.customer_id
            ORDER BY datetime(p.payment_date) DESC, datetime(p.created_at) DESC
          ''')
        : await db.rawQuery(
            '''
            SELECT p.*, c.name AS customer_name
            FROM payments p
            INNER JOIN customers c ON c.id = p.customer_id
            WHERE p.customer_id = ?
            ORDER BY datetime(p.payment_date) DESC, datetime(p.created_at) DESC
            ''',
            [customerId],
          );

    return rows.map(PaymentModel.fromMap).toList();
  }

  Future<PaymentModel> getById(int id) async {
    final db = await _db();
    final rows = await db.rawQuery(
      '''
      SELECT p.*, c.name AS customer_name
      FROM payments p
      INNER JOIN customers c ON c.id = p.customer_id
      WHERE p.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) throw PaymentNotFoundException(id);
    return PaymentModel.fromMap(rows.first);
  }

  Future<double> availableBalance(
    int customerId, {
    int? excludePaymentId,
  }) async {
    final db = await _db();
    await _balanceService.syncCustomer(db, customerId);
    final available = await _balanceService.availableBalance(db, customerId);
    if (excludePaymentId == null) return available;

    final existing = await getById(excludePaymentId);
    // When editing, current payment amount is already applied — add it back.
    return available + existing.paymentAmount;
  }

  Future<PaymentModel> add({
    required int customerId,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final db = await _db();
    await _balanceService.syncCustomer(db, customerId);
    final available = await _balanceService.availableBalance(db, customerId);
    if (paymentAmount > available + 0.0001) {
      throw PaymentExceedsBalanceException(available);
    }

    final now = DateTime.now();
    final id = await db.insert('payments', {
      'customer_id': customerId,
      'payment_date': paymentDate.toIso8601String(),
      'payment_amount': paymentAmount,
      'remaining_balance': 0,
      'notes': _nullableTrim(notes),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await _balanceService.syncCustomer(db, customerId);
    return getById(id);
  }

  Future<PaymentModel> updatePayment({
    required int id,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final db = await _db();
    final existing = await getById(id);
    final available = await availableBalance(
      existing.customerId,
      excludePaymentId: id,
    );
    if (paymentAmount > available + 0.0001) {
      throw PaymentExceedsBalanceException(available);
    }

    final updated = await db.update(
      'payments',
      {
        'payment_date': paymentDate.toIso8601String(),
        'payment_amount': paymentAmount,
        'notes': _nullableTrim(notes),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (updated == 0) throw PaymentNotFoundException(id);

    await _balanceService.syncCustomer(db, existing.customerId);
    return getById(id);
  }

  Future<void> delete(int id) async {
    final db = await _db();
    final existing = await getById(id);
    final deleted = await db.delete(
      'payments',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (deleted == 0) throw PaymentNotFoundException(id);
    await _balanceService.syncCustomer(db, existing.customerId);
  }

  String? _nullableTrim(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
