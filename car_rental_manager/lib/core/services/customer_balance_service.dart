import 'package:sqflite/sqflite.dart';

/// Recalculates transaction remaining balances from receipt + linked payments.
///
/// Customer totals are not stored; they are computed in queries via joins.
///
/// remaining_amount = total_amount - received_amount - SUM(payments.payment_amount)
class CustomerBalanceService {
  const CustomerBalanceService();

  Future<void> syncCustomer(DatabaseExecutor db, int customerId) async {
    final txs = await db.query(
      'transactions',
      columns: ['id'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
    );
    for (final row in txs) {
      await syncTransaction(db, row['id'] as int);
    }
  }

  Future<void> syncTransaction(DatabaseExecutor db, int transactionId) async {
    final rows = await db.query(
      'transactions',
      columns: ['id', 'total_amount', 'received_amount', 'customer_id'],
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final total = (rows.first['total_amount'] as num?)?.toDouble() ?? 0;
    final received = (rows.first['received_amount'] as num?)?.toDouble() ?? 0;
    final paidRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payment_amount), 0) AS paid
      FROM payments
      WHERE transaction_id = ?
      ''',
      [transactionId],
    );
    final paid = (paidRows.first['paid'] as num?)?.toDouble() ?? 0;
    var remaining = total - received - paid;
    if (remaining < 0) remaining = 0;

    await db.update(
      'transactions',
      {
        'remaining_amount': remaining,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<double> availableForTransaction(
    DatabaseExecutor db,
    int transactionId, {
    int? excludePaymentId,
  }) async {
    await syncTransaction(db, transactionId);
    final rows = await db.query(
      'transactions',
      columns: ['remaining_amount'],
      where: 'id = ?',
      whereArgs: [transactionId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    var available = (rows.first['remaining_amount'] as num?)?.toDouble() ?? 0;
    if (excludePaymentId != null) {
      final pay = await db.query(
        'payments',
        columns: ['payment_amount'],
        where: 'id = ?',
        whereArgs: [excludePaymentId],
        limit: 1,
      );
      if (pay.isNotEmpty) {
        available += (pay.first['payment_amount'] as num?)?.toDouble() ?? 0;
      }
    }
    return available;
  }

  Future<double> availableBalance(DatabaseExecutor db, int customerId) async {
    await syncCustomer(db, customerId);
    final rows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(remaining_amount), 0) AS remaining
      FROM transactions
      WHERE customer_id = ?
      ''',
      [customerId],
    );
    return (rows.first['remaining'] as num?)?.toDouble() ?? 0;
  }
}
