import 'outstanding_customer.dart';

/// UI filter/state helpers shared across report screens.
class ReportsState {
  const ReportsState({
    this.selectedDate,
    this.selectedYear,
    this.selectedMonth,
    this.selectedCustomerId,
    this.outstandingQuery = '',
    this.outstandingSort = OutstandingSort.highestBalance,
  });

  final DateTime? selectedDate;
  final int? selectedYear;
  final int? selectedMonth;
  final int? selectedCustomerId;
  final String outstandingQuery;
  final OutstandingSort outstandingSort;

  static ReportsState initial() {
    final now = DateTime.now();
    return ReportsState(
      selectedDate: DateTime(now.year, now.month, now.day),
      selectedYear: now.year,
      selectedMonth: now.month,
    );
  }

  ReportsState copyWith({
    DateTime? selectedDate,
    int? selectedYear,
    int? selectedMonth,
    int? selectedCustomerId,
    String? outstandingQuery,
    OutstandingSort? outstandingSort,
    bool clearCustomerId = false,
  }) {
    return ReportsState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedCustomerId:
          clearCustomerId ? null : (selectedCustomerId ?? this.selectedCustomerId),
      outstandingQuery: outstandingQuery ?? this.outstandingQuery,
      outstandingSort: outstandingSort ?? this.outstandingSort,
    );
  }
}
