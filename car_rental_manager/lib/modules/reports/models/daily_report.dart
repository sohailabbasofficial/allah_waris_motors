import 'report_transaction_row.dart';

/// Aggregated business report for a single calendar day.
class DailyReport {
  const DailyReport({
    required this.date,
    required this.totalTransactions,
    required this.totalAmount,
    required this.totalPaymentsReceived,
    required this.remainingBalance,
    required this.customersServed,
    required this.transactions,
  });

  final DateTime date;
  final int totalTransactions;
  final double totalAmount;
  final double totalPaymentsReceived;
  final double remainingBalance;
  final int customersServed;
  final List<ReportTransactionRow> transactions;

  bool get hasData =>
      totalTransactions > 0 || totalPaymentsReceived > 0 || customersServed > 0;

  static DailyReport empty(DateTime date) => DailyReport(
        date: date,
        totalTransactions: 0,
        totalAmount: 0,
        totalPaymentsReceived: 0,
        remainingBalance: 0,
        customersServed: 0,
        transactions: const [],
      );
}
