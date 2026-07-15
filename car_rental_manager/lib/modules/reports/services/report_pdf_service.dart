import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/customer_ledger.dart';
import '../models/daily_report.dart';
import '../models/monthly_report.dart';
import '../models/outstanding_customer.dart';

/// Builds shareable report text. PDF generation is a placeholder
/// until a PDF package is added to the project.
class ReportPdfService {
  const ReportPdfService();

  static final _date = DateFormat('dd MMM yyyy');
  static final _month = DateFormat('MMMM yyyy');

  Future<String> dailyReportText(DailyReport report) async {
    final buffer = StringBuffer()
      ..writeln(AppConstants.appName)
      ..writeln('Daily Report')
      ..writeln('Generated: ${_date.format(DateTime.now())}')
      ..writeln('Report date: ${_date.format(report.date)}')
      ..writeln('')
      ..writeln('Total Transactions: ${report.totalTransactions}')
      ..writeln('Total Amount: ${CurrencyFormatter.format(report.totalAmount)}')
      ..writeln(
        'Payments Received: ${CurrencyFormatter.format(report.totalPaymentsReceived)}',
      )
      ..writeln(
        'Remaining Balance: ${CurrencyFormatter.format(report.remainingBalance)}',
      )
      ..writeln('Customers Served: ${report.customersServed}')
      ..writeln('')
      ..writeln('Transactions');

    if (report.transactions.isEmpty) {
      buffer.writeln('No transactions for this day.');
    } else {
      for (final tx in report.transactions) {
        buffer.writeln(
          '- ${_date.format(tx.date)} | ${tx.customerName} | '
          '${tx.description} | ${CurrencyFormatter.format(tx.totalAmount)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('— End of report —');
    return buffer.toString();
  }

  Future<String> monthlyReportText(MonthlyReport report) async {
    final period = _month.format(DateTime(report.year, report.month));
    final buffer = StringBuffer()
      ..writeln(AppConstants.appName)
      ..writeln('Monthly Report')
      ..writeln('Generated: ${_date.format(DateTime.now())}')
      ..writeln('Period: $period')
      ..writeln('')
      ..writeln('Total Transactions: ${report.totalTransactions}')
      ..writeln(
        'Total Revenue: ${CurrencyFormatter.format(report.totalRevenue)}',
      )
      ..writeln(
        'Payments Received: ${CurrencyFormatter.format(report.totalPaymentsReceived)}',
      )
      ..writeln(
        'Outstanding Balance: ${CurrencyFormatter.format(report.outstandingBalance)}',
      )
      ..writeln('New Customers: ${report.newCustomersAdded}')
      ..writeln(
        'Monthly Collection: ${CurrencyFormatter.format(report.monthlyCollection)}',
      )
      ..writeln('')
      ..writeln('Transactions');

    if (report.transactions.isEmpty) {
      buffer.writeln('No transactions for this month.');
    } else {
      for (final tx in report.transactions) {
        buffer.writeln(
          '- ${_date.format(tx.date)} | ${tx.customerName} | '
          '${CurrencyFormatter.format(tx.totalAmount)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('— End of report —');
    return buffer.toString();
  }

  Future<String> customerLedgerText(CustomerLedger ledger) async {
    final c = ledger.customer;
    final buffer = StringBuffer()
      ..writeln(AppConstants.appName)
      ..writeln('Customer Ledger')
      ..writeln('Generated: ${_date.format(DateTime.now())}')
      ..writeln('')
      ..writeln('Name: ${c.name}')
      ..writeln('Phone: ${c.phone}')
      ..writeln('CNIC: ${c.cnic?.trim().isNotEmpty == true ? c.cnic : '-'}')
      ..writeln(
        'Address: ${c.address?.trim().isNotEmpty == true ? c.address : '-'}',
      )
      ..writeln('')
      ..writeln('Total Amount: ${CurrencyFormatter.format(ledger.totalAmount)}')
      ..writeln('Total Paid: ${CurrencyFormatter.format(ledger.totalPaid)}')
      ..writeln(
        'Remaining: ${CurrencyFormatter.format(ledger.remainingBalance)}',
      )
      ..writeln('')
      ..writeln('Ledger');

    if (ledger.entries.isEmpty) {
      buffer.writeln('No ledger entries.');
    } else {
      for (final e in ledger.entries) {
        buffer.writeln(
          '- ${_date.format(e.date)} | ${e.description} | '
          'Debit ${CurrencyFormatter.format(e.debit)} | '
          'Credit ${CurrencyFormatter.format(e.credit)} | '
          'Bal ${CurrencyFormatter.format(e.runningBalance)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('— End of report —');
    return buffer.toString();
  }

  Future<String> outstandingCustomersText(
    List<OutstandingCustomer> items,
  ) async {
    final buffer = StringBuffer()
      ..writeln(AppConstants.appName)
      ..writeln('Outstanding Customers')
      ..writeln('Generated: ${_date.format(DateTime.now())}')
      ..writeln('Count: ${items.length}')
      ..writeln('');

    if (items.isEmpty) {
      buffer.writeln('No outstanding customers.');
    } else {
      for (final item in items) {
        buffer.writeln(
          '- ${item.name} (${item.phone}) | '
          'Total ${CurrencyFormatter.format(item.totalAmount)} | '
          'Paid ${CurrencyFormatter.format(item.totalPaid)} | '
          'Due ${CurrencyFormatter.format(item.remainingBalance)}',
        );
      }
    }

    buffer
      ..writeln('')
      ..writeln('— End of report —');
    return buffer.toString();
  }

  /// Copies a text report to the clipboard as a PDF-export stand-in.
  Future<void> copyToClipboard(String content) {
    return Clipboard.setData(ClipboardData(text: content));
  }

  /// Placeholder for true PDF generation (optional feature).
  Future<void> exportPdfPlaceholder(String reportTitle) async {
    throw UnimplementedError(
      'PDF export for "$reportTitle" is not enabled yet. '
      'Use Copy Text Export instead, or add the pdf/printing packages.',
    );
  }
}
