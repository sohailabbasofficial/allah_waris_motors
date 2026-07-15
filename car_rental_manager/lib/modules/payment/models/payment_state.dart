import 'payment_model.dart';

class PaymentState {
  const PaymentState({
    required this.payments,
    this.query = '',
    this.filterDate,
    this.customerIdFilter,
  });

  final List<PaymentModel> payments;
  final String query;
  final DateTime? filterDate;
  final int? customerIdFilter;

  static const empty = PaymentState(payments: []);

  List<PaymentModel> get filtered {
    final q = query.trim().toLowerCase();
    return payments.where((p) {
      final matchesName =
          q.isEmpty || p.customerName.toLowerCase().contains(q);
      final matchesDate = filterDate == null ||
          (p.paymentDate.year == filterDate!.year &&
              p.paymentDate.month == filterDate!.month &&
              p.paymentDate.day == filterDate!.day);
      final matchesCustomer =
          customerIdFilter == null || p.customerId == customerIdFilter;
      return matchesName && matchesDate && matchesCustomer;
    }).toList();
  }

  PaymentState copyWith({
    List<PaymentModel>? payments,
    String? query,
    DateTime? filterDate,
    bool clearFilterDate = false,
    int? customerIdFilter,
    bool clearCustomerFilter = false,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      query: query ?? this.query,
      filterDate: clearFilterDate ? null : (filterDate ?? this.filterDate),
      customerIdFilter: clearCustomerFilter
          ? null
          : (customerIdFilter ?? this.customerIdFilter),
    );
  }
}
