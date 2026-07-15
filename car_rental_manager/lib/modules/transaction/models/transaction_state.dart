import 'transaction_model.dart';

/// List UI state for transactions (search + optional date filter).
class TransactionState {
  const TransactionState({
    required this.transactions,
    this.query = '',
    this.filterDate,
  });

  final List<TransactionModel> transactions;
  final String query;
  final DateTime? filterDate;

  static const empty = TransactionState(transactions: []);

  List<TransactionModel> get filtered {
    final q = query.trim().toLowerCase();
    return transactions.where((t) {
      final matchesName =
          q.isEmpty || t.customerName.toLowerCase().contains(q);
      final matchesDate = filterDate == null ||
          (t.date.year == filterDate!.year &&
              t.date.month == filterDate!.month &&
              t.date.day == filterDate!.day);
      return matchesName && matchesDate;
    }).toList();
  }

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    String? query,
    DateTime? filterDate,
    bool clearFilterDate = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      query: query ?? this.query,
      filterDate: clearFilterDate ? null : (filterDate ?? this.filterDate),
    );
  }
}
