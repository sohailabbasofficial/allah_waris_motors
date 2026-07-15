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

  static const _select = '''
SELECT
  p.id AS id,
  p.transaction_id AS transaction_id,
  p.payment_amount AS payment_amount,
  p.payment_date AS payment_date,
  p.notes AS notes,
  p.created_at AS created_at,
  t.customer_id AS customer_id,
  c.name AS customer_name,
  t.remaining_amount AS remaining_balance
FROM payments p
INNER JOIN transactions t ON t.id = p.transaction_id
INNER JOIN customers c ON c.id = t.customer_id
''';

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
            $_select
            ORDER BY datetime(p.payment_date) DESC, datetime(p.created_at) DESC
          ''')
        : await db.rawQuery(
            '''
            $_select
            WHERE t.customer_id = ?
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
      $_select
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
    var available = await _balanceService.availableBalance(db, customerId);
    if (excludePaymentId != null) {
      final existing = await getById(excludePaymentId);
      available += existing.paymentAmount;
    }
    return available;
  }

  Future<double> availableForTransaction(
    int transactionId, {
    int? excludePaymentId,
  }) async {
    final db = await _db();
    return _balanceService.availableForTransaction(
      db,
      transactionId,
      excludePaymentId: excludePaymentId,
    );
  }

  Future<PaymentModel> add({
    required int transactionId,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final db = await _db();
    final id = await db.transaction((txn) async {
      final available = await _balanceService.availableForTransaction(
        txn,
        transactionId,
      );
      if (paymentAmount > available + 0.0001) {
        throw PaymentExceedsBalanceException(available);
      }

      final now = DateTime.now();
      final newId = await txn.insert('payments', {
        'transaction_id': transactionId,
        'payment_date': paymentDate.toIso8601String(),
        'payment_amount': paymentAmount,
        'notes': _nullableTrim(notes),
        'created_at': now.toIso8601String(),
      });

      await _balanceService.syncTransaction(txn, transactionId);
      return newId;
    });
    return getById(id);
  }

  Future<PaymentModel> updatePayment({
    required int id,
    required DateTime paymentDate,
    required double paymentAmount,
    String? notes,
  }) async {
    final existing = await getById(id);
    final available = await availableForTransaction(
      existing.transactionId,
      excludePaymentId: id,
    );
    if (paymentAmount > available + 0.0001) {
      throw PaymentExceedsBalanceException(available);
    }

    final db = await _db();
    await db.transaction((txn) async {
      final updated = await txn.update(
        'payments',
        {
          'payment_date': paymentDate.toIso8601String(),
          'payment_amount': paymentAmount,
          'notes': _nullableTrim(notes),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      if (updated == 0) throw PaymentNotFoundException(id);
      await _balanceService.syncTransaction(txn, existing.transactionId);
    });

    return getById(id);
  }

  Future<void> delete(int id) async {
    final existing = await getById(id);
    final db = await _db();
    await db.transaction((txn) async {
      final deleted = await txn.delete(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (deleted == 0) throw PaymentNotFoundException(id);
      await _balanceService.syncTransaction(txn, existing.transactionId);
    });
  }

  String? _nullableTrim(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
