import 'customer_model.dart';

/// UI state for the customer list (raw list + search query).
class CustomerState {
  const CustomerState({
    required this.customers,
    this.query = '',
  });

  final List<CustomerModel> customers;
  final String query;

  static const empty = CustomerState(customers: []);

  List<CustomerModel> get filtered {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return customers;
    return customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          c.phone.toLowerCase().contains(q);
    }).toList();
  }

  CustomerState copyWith({
    List<CustomerModel>? customers,
    String? query,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      query: query ?? this.query,
    );
  }
}
