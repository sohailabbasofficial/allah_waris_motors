import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../customer/data/customer_local_data_source.dart';
import '../models/dashboard_stats.dart';
import '../models/recent_customer.dart';
import '../models/recent_transaction.dart';

/// SQLite queries for dashboard aggregates and recent lists.
class DashboardLocalDataSource {
  DashboardLocalDataSource(this._db);

  final Database _db;

  Future<DashboardStats> fetchStats() async {
    final customersResult = await _db.rawQuery(
      'SELECT COUNT(*) AS count FROM customers',
    );
    final totalsResult = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(total_amount), 0) AS total_udhaar,
        COALESCE(SUM(received_amount), 0) AS tx_received
      FROM transactions
    ''');
    final payResult = await _db.rawQuery('''
      SELECT COALESCE(SUM(payment_amount), 0) AS pay_received
      FROM payments
    ''');

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayResult = await _db.rawQuery(
      '''
      SELECT
        (
          SELECT COALESCE(SUM(received_amount), 0)
          FROM transactions
          WHERE date(transaction_date) = date(?)
        ) +
        (
          SELECT COALESCE(SUM(payment_amount), 0)
          FROM payments
          WHERE date(payment_date) = date(?)
        ) AS today_total
      ''',
      [today, today],
    );

    final totalCustomers =
        (customersResult.first['count'] as num?)?.toInt() ?? 0;
    final totalUdhaar =
        (totalsResult.first['total_udhaar'] as num?)?.toDouble() ?? 0;
    final txReceived =
        (totalsResult.first['tx_received'] as num?)?.toDouble() ?? 0;
    final payReceived =
        (payResult.first['pay_received'] as num?)?.toDouble() ?? 0;
    final totalReceived = txReceived + payReceived;
    final todaysCollection =
        (todayResult.first['today_total'] as num?)?.toDouble() ?? 0;

    return DashboardStats(
      totalCustomers: totalCustomers,
      totalUdhaar: totalUdhaar,
      totalReceived: totalReceived,
      remainingBalance: totalUdhaar - totalReceived,
      todaysCollection: todaysCollection,
    );
  }

  Future<List<RecentCustomer>> fetchRecentCustomers({int limit = 5}) async {
    final rows = await _db.rawQuery(
      '''
      $customerSelectWithBalances
      ORDER BY datetime(c.created_at) DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(RecentCustomer.fromMap).toList();
  }

  Future<List<RecentTransaction>> fetchRecentTransactions({
    int limit = 5,
  }) async {
    final rows = await _db.rawQuery(
      '''
      SELECT
        t.id AS id,
        c.name AS customer_name,
        t.received_amount AS amount,
        t.transaction_date AS paid_at,
        t.description AS payment_method
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      ORDER BY datetime(t.transaction_date) DESC, datetime(t.created_at) DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(RecentTransaction.fromMap).toList();
  }
}
