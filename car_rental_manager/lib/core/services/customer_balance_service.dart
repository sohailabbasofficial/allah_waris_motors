import 'package:sqflite/sqflite.dart';

/// Recalculates customer financial totals from transactions + payments.
///
/// Rules:
/// - total_udhaar = SUM(transactions.total_amount)
/// - total_received = SUM(transactions.received_amount) + SUM(payments.payment_amount)
/// - remaining_balance = total_udhaar - total_received
///
/// Also rewrites each payment's remaining_balance after payment in date order.
class CustomerBalanceService {
  const CustomerBalanceService();

  Future<void> syncCustomer(Database db, int customerId) async {
    final txRows = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total_amount), 0) AS total_udhaar,
        COALESCE(SUM(received_amount), 0) AS tx_received
      FROM transactions
      WHERE customer_id = ?
      ''',
      [customerId],
    );

    final payRows = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payment_amount), 0) AS pay_received
      FROM payments
      WHERE customer_id = ?
      ''',
      [customerId],
    );

    final totalUdhaar =
        (txRows.first['total_udhaar'] as num?)?.toDouble() ?? 0;
    final txReceived = (txRows.first['tx_received'] as num?)?.toDouble() ?? 0;
    final payReceived =
        (payRows.first['pay_received'] as num?)?.toDouble() ?? 0;
    final totalReceived = txReceived + payReceived;
    final remaining = totalUdhaar - totalReceived;

    await db.update(
      'customers',
      {
        'total_udhaar': totalUdhaar,
        'total_received': totalReceived,
        'remaining_balance': remaining < 0 ? 0 : remaining,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );

    await _rewritePaymentRemainings(
      db,
      customerId,
      openingRemaining: totalUdhaar - txReceived,
    );
  }

  /// Applies payments chronologically against balances remaining after transaction
  /// receipts, and stores each payment's post-payment remaining.
  Future<void> _rewritePaymentRemainings(
    Database db,
    int customerId, {
    required double openingRemaining,
  }) async {
    final payments = await db.query(
      'payments',
      columns: ['id', 'payment_amount'],
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'datetime(payment_date) ASC, datetime(created_at) ASC, id ASC',
    );

    var running = openingRemaining;
    for (final row in payments) {
      final amount = (row['payment_amount'] as num?)?.toDouble() ?? 0;
      running -= amount;
      final after = running < 0 ? 0.0 : running;
      await db.update(
        'payments',
        {'remaining_balance': after},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }

  /// Remaining that can still be paid (before inserting a new payment).
  Future<double> availableBalance(Database db, int customerId) async {
    final rows = await db.query(
      'customers',
      columns: ['remaining_balance'],
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (rows.isEmpty) return 0;
    return (rows.first['remaining_balance'] as num?)?.toDouble() ?? 0;
  }
}
