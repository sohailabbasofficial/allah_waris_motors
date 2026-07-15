import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

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
        COALESCE(SUM(total_udhaar), 0) AS total_udhaar,
        COALESCE(SUM(total_received), 0) AS total_received
      FROM customers
    ''');

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayResult = await _db.rawQuery(
      '''
      SELECT
        (
          SELECT COALESCE(SUM(received_amount), 0)
          FROM transactions
          WHERE date(date) = date(?)
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
    final totalReceived =
        (totalsResult.first['total_received'] as num?)?.toDouble() ?? 0;
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
    final rows = await _db.query(
      'customers',
      columns: ['id', 'name', 'phone', 'remaining_balance'],
      orderBy: 'datetime(created_at) DESC',
      limit: limit,
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
        t.date AS paid_at,
        t.description AS payment_method
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      ORDER BY datetime(t.date) DESC, datetime(t.created_at) DESC
      LIMIT ?
      ''',
      [limit],
    );
    return rows.map(RecentTransaction.fromMap).toList();
  }
}
