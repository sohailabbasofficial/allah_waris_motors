import 'report_transaction_row.dart';

/// Aggregated business report for a calendar month.
class MonthlyReport {
  const MonthlyReport({
    required this.year,
    required this.month,
    required this.totalTransactions,
    required this.totalRevenue,
    required this.totalPaymentsReceived,
    required this.outstandingBalance,
    required this.newCustomersAdded,
    required this.monthlyCollection,
    required this.transactions,
  });

  final int year;
  final int month;
  final int totalTransactions;
  final double totalRevenue;
  final double totalPaymentsReceived;
  final double outstandingBalance;
  final int newCustomersAdded;
  final double monthlyCollection;
  final List<ReportTransactionRow> transactions;

  bool get hasData =>
      totalTransactions > 0 ||
      totalPaymentsReceived > 0 ||
      newCustomersAdded > 0;

  static MonthlyReport empty(int year, int month) => MonthlyReport(
        year: year,
        month: month,
        totalTransactions: 0,
        totalRevenue: 0,
        totalPaymentsReceived: 0,
        outstandingBalance: 0,
        newCustomersAdded: 0,
        monthlyCollection: 0,
        transactions: const [],
      );
}
