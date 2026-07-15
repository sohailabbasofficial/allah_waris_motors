import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../../customer/providers/customer_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/customer_ledger.dart';
import '../models/daily_report.dart';
import '../models/monthly_report.dart';
import '../models/outstanding_customer.dart';
import '../models/reports_state.dart';
import '../repository/reports_repository.dart';
import '../services/report_pdf_service.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(databaseHelperProvider));
});

final reportPdfServiceProvider = Provider<ReportPdfService>((ref) {
  return const ReportPdfService();
});

/// Shared filter/selection state for report screens.
final reportsUiProvider =
    NotifierProvider<ReportsUiNotifier, ReportsState>(ReportsUiNotifier.new);

class ReportsUiNotifier extends Notifier<ReportsState> {
  @override
  ReportsState build() => ReportsState.initial();

  void setDate(DateTime date) {
    state = state.copyWith(
      selectedDate: DateTime(date.year, date.month, date.day),
    );
  }

  void setMonthYear(int year, int month) {
    state = state.copyWith(selectedYear: year, selectedMonth: month);
  }

  void setCustomerId(int? customerId) {
    state = state.copyWith(
      selectedCustomerId: customerId,
      clearCustomerId: customerId == null,
    );
  }

  void setOutstandingQuery(String query) {
    state = state.copyWith(outstandingQuery: query);
  }

  void setOutstandingSort(OutstandingSort sort) {
    state = state.copyWith(outstandingSort: sort);
  }
}

/// Keeps report providers in sync when underlying modules change.
void _watchSourceData(Ref ref) {
  ref.watch(dashboardProvider);
  ref.watch(customerListProvider);
  ref.watch(transactionListProvider);
  ref.watch(paymentListProvider);
}

final dailyReportProvider =
    FutureProvider.autoDispose.family<DailyReport, DateTime>((ref, date) async {
  _watchSourceData(ref);
  final day = DateTime(date.year, date.month, date.day);
  return ref.watch(reportsRepositoryProvider).fetchDailyReport(day);
});

final monthlyReportProvider = FutureProvider.autoDispose
    .family<MonthlyReport, ({int year, int month})>((ref, period) async {
  _watchSourceData(ref);
  return ref.watch(reportsRepositoryProvider).fetchMonthlyReport(
        period.year,
        period.month,
      );
});

final customerLedgerProvider =
    FutureProvider.autoDispose.family<CustomerLedger?, int>((ref, id) async {
  _watchSourceData(ref);
  return ref.watch(reportsRepositoryProvider).fetchCustomerLedger(id);
});

final outstandingCustomersProvider =
    FutureProvider.autoDispose<List<OutstandingCustomer>>((ref) async {
  _watchSourceData(ref);
  final ui = ref.watch(reportsUiProvider);
  return ref.watch(reportsRepositoryProvider).fetchOutstandingCustomers(
        query: ui.outstandingQuery,
        sort: ui.outstandingSort,
      );
});

/// Alias matching the requested ReportsProvider name.
final reportsProvider = reportsUiProvider;
