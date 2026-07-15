import '../../customer/models/customer_model.dart';
import 'ledger_entry.dart';

/// Full ledger snapshot for one customer.
class CustomerLedger {
  const CustomerLedger({
    required this.customer,
    required this.entries,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingBalance,
  });

  final CustomerModel customer;
  final List<LedgerEntry> entries;
  final double totalAmount;
  final double totalPaid;
  final double remainingBalance;

  bool get hasData => entries.isNotEmpty;
}
