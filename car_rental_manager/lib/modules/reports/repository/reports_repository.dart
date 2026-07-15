import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';
import '../../customer/models/customer_model.dart';
import '../models/customer_ledger.dart';
import '../models/daily_report.dart';
import '../models/ledger_entry.dart';
import '../models/monthly_report.dart';
import '../models/outstanding_customer.dart';
import '../models/report_transaction_row.dart';

class ReportsRepository {
  ReportsRepository(this._helper);

  final DatabaseHelper _helper;
  static final _dayKey = DateFormat('yyyy-MM-dd');

  Future<Database?> get _dbOrNull => _helper.databaseOrNull;

  Future<DailyReport> fetchDailyReport(DateTime date) async {
    final db = await _dbOrNull;
    if (db == null) return DailyReport.empty(date);

    final day = _dayKey.format(date);

    final txAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_transactions,
        COALESCE(SUM(total_amount), 0) AS total_amount,
        COALESCE(SUM(received_amount), 0) AS tx_received,
        COALESCE(SUM(remaining_amount), 0) AS remaining_balance
      FROM transactions
      WHERE date(date) = date(?)
      ''',
      [day],
    );

    final payAgg = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payment_amount), 0) AS pay_received
      FROM payments
      WHERE date(payment_date) = date(?)
      ''',
      [day],
    );

    final customersAgg = await db.rawQuery(
      '''
      SELECT COUNT(*) AS served FROM (
        SELECT customer_id FROM transactions WHERE date(date) = date(?)
        UNION
        SELECT customer_id FROM payments WHERE date(payment_date) = date(?)
      )
      ''',
      [day, day],
    );

    final rows = await db.rawQuery(
      '''
      SELECT
        t.id AS id,
        t.customer_id AS customer_id,
        c.name AS customer_name,
        t.date AS date,
        t.description AS description,
        t.total_amount AS total_amount,
        t.received_amount AS received_amount,
        t.remaining_amount AS remaining_amount,
        t.notes AS notes
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      WHERE date(t.date) = date(?)
      ORDER BY datetime(t.date) ASC, datetime(t.created_at) ASC, t.id ASC
      ''',
      [day],
    );

    final txReceived = (txAgg.first['tx_received'] as num?)?.toDouble() ?? 0;
    final payReceived = (payAgg.first['pay_received'] as num?)?.toDouble() ?? 0;

    return DailyReport(
      date: date,
      totalTransactions:
          (txAgg.first['total_transactions'] as num?)?.toInt() ?? 0,
      totalAmount: (txAgg.first['total_amount'] as num?)?.toDouble() ?? 0,
      totalPaymentsReceived: txReceived + payReceived,
      remainingBalance:
          (txAgg.first['remaining_balance'] as num?)?.toDouble() ?? 0,
      customersServed: (customersAgg.first['served'] as num?)?.toInt() ?? 0,
      transactions: rows.map(ReportTransactionRow.fromMap).toList(),
    );
  }

  Future<MonthlyReport> fetchMonthlyReport(int year, int month) async {
    final db = await _dbOrNull;
    if (db == null) return MonthlyReport.empty(year, month);

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);
    final startKey = _dayKey.format(start);
    final endKey = _dayKey.format(end);

    final txAgg = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total_transactions,
        COALESCE(SUM(total_amount), 0) AS total_revenue,
        COALESCE(SUM(received_amount), 0) AS tx_received
      FROM transactions
      WHERE date(date) >= date(?) AND date(date) < date(?)
      ''',
      [startKey, endKey],
    );

    final payAgg = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(payment_amount), 0) AS pay_received
      FROM payments
      WHERE date(payment_date) >= date(?) AND date(payment_date) < date(?)
      ''',
      [startKey, endKey],
    );

    final outstanding = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(remaining_balance), 0) AS outstanding
      FROM customers
      ''',
    );

    final newCustomers = await db.rawQuery(
      '''
      SELECT COUNT(*) AS count
      FROM customers
      WHERE date(created_at) >= date(?) AND date(created_at) < date(?)
      ''',
      [startKey, endKey],
    );

    final rows = await db.rawQuery(
      '''
      SELECT
        t.id AS id,
        t.customer_id AS customer_id,
        c.name AS customer_name,
        t.date AS date,
        t.description AS description,
        t.total_amount AS total_amount,
        t.received_amount AS received_amount,
        t.remaining_amount AS remaining_amount,
        t.notes AS notes
      FROM transactions t
      INNER JOIN customers c ON c.id = t.customer_id
      WHERE date(t.date) >= date(?) AND date(t.date) < date(?)
      ORDER BY datetime(t.date) ASC, datetime(t.created_at) ASC, t.id ASC
      ''',
      [startKey, endKey],
    );

    final txReceived = (txAgg.first['tx_received'] as num?)?.toDouble() ?? 0;
    final payReceived = (payAgg.first['pay_received'] as num?)?.toDouble() ?? 0;
    final collection = txReceived + payReceived;

    return MonthlyReport(
      year: year,
      month: month,
      totalTransactions:
          (txAgg.first['total_transactions'] as num?)?.toInt() ?? 0,
      totalRevenue: (txAgg.first['total_revenue'] as num?)?.toDouble() ?? 0,
      totalPaymentsReceived: collection,
      outstandingBalance:
          (outstanding.first['outstanding'] as num?)?.toDouble() ?? 0,
      newCustomersAdded: (newCustomers.first['count'] as num?)?.toInt() ?? 0,
      monthlyCollection: collection,
      transactions: rows.map(ReportTransactionRow.fromMap).toList(),
    );
  }

  Future<CustomerLedger?> fetchCustomerLedger(int customerId) async {
    final db = await _dbOrNull;
    if (db == null) return null;

    final customerRows = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (customerRows.isEmpty) return null;

    final customer = CustomerModel.fromMap(customerRows.first);

    final txRows = await db.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'datetime(date) ASC, datetime(created_at) ASC, id ASC',
    );

    final payRows = await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy:
          'datetime(payment_date) ASC, datetime(created_at) ASC, id ASC',
    );

    final draft = <_LedgerDraft>[];

    for (final row in txRows) {
      final date =
          DateTime.tryParse((row['date'] as String?) ?? '') ?? DateTime.now();
      final total = (row['total_amount'] as num?)?.toDouble() ?? 0;
      final received = (row['received_amount'] as num?)?.toDouble() ?? 0;
      final description = (row['description'] as String?) ?? 'Transaction';
      final notes = row['notes'] as String?;
      final id = row['id'] as int;

      draft.add(
        _LedgerDraft(
          type: LedgerEntryType.transaction,
          date: date,
          sortKey: date,
          id: id,
          description: description,
          debit: total,
          credit: received,
          notes: notes,
        ),
      );
    }

    for (final row in payRows) {
      final date =
          DateTime.tryParse((row['payment_date'] as String?) ?? '') ??
              DateTime.now();
      final amount = (row['payment_amount'] as num?)?.toDouble() ?? 0;
      final notes = row['notes'] as String?;
      final id = row['id'] as int;

      draft.add(
        _LedgerDraft(
          type: LedgerEntryType.payment,
          date: date,
          sortKey: date,
          id: id,
          description: 'Payment received',
          debit: 0,
          credit: amount,
          notes: notes,
        ),
      );
    }

    draft.sort((a, b) {
      final byDate = a.sortKey.compareTo(b.sortKey);
      if (byDate != 0) return byDate;
      // Transactions before payments on the same instant for stable balances.
      if (a.type != b.type) {
        return a.type == LedgerEntryType.transaction ? -1 : 1;
      }
      return a.id.compareTo(b.id);
    });

    var running = 0.0;
    final entries = <LedgerEntry>[];
    for (final item in draft) {
      running += item.debit - item.credit;
      if (running < 0) running = 0;
      entries.add(
        LedgerEntry(
          type: item.type,
          date: item.date,
          description: item.description,
          debit: item.debit,
          credit: item.credit,
          runningBalance: running,
          referenceId: item.id,
          notes: item.notes,
        ),
      );
    }

    return CustomerLedger(
      customer: customer,
      entries: entries,
      totalAmount: customer.totalUdhaar,
      totalPaid: customer.totalReceived,
      remainingBalance: customer.remainingBalance,
    );
  }

  Future<List<OutstandingCustomer>> fetchOutstandingCustomers({
    String query = '',
    OutstandingSort sort = OutstandingSort.highestBalance,
  }) async {
    final db = await _dbOrNull;
    if (db == null) return [];

    final orderBy = sort == OutstandingSort.highestBalance
        ? 'remaining_balance DESC, name COLLATE NOCASE ASC'
        : 'remaining_balance ASC, name COLLATE NOCASE ASC';

    final q = query.trim();
    final rows = q.isEmpty
        ? await db.query(
            'customers',
            columns: [
              'id',
              'name',
              'phone',
              'total_udhaar',
              'total_received',
              'remaining_balance',
            ],
            where: 'remaining_balance > 0',
            orderBy: orderBy,
          )
        : await db.query(
            'customers',
            columns: [
              'id',
              'name',
              'phone',
              'total_udhaar',
              'total_received',
              'remaining_balance',
            ],
            where: 'remaining_balance > 0 AND name LIKE ?',
            whereArgs: ['%$q%'],
            orderBy: orderBy,
          );

    return rows.map(OutstandingCustomer.fromMap).toList();
  }
}

class _LedgerDraft {
  const _LedgerDraft({
    required this.type,
    required this.date,
    required this.sortKey,
    required this.id,
    required this.description,
    required this.debit,
    required this.credit,
    this.notes,
  });

  final LedgerEntryType type;
  final DateTime date;
  final DateTime sortKey;
  final int id;
  final String description;
  final double debit;
  final double credit;
  final String? notes;
}
