/// Lightweight transaction row for the dashboard recent list.
class RecentTransaction {
  const RecentTransaction({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.paidAt,
    this.paymentMethod,
  });

  final int id;
  final String customerName;
  final double amount;
  final DateTime paidAt;
  final String? paymentMethod;

  factory RecentTransaction.fromMap(Map<String, Object?> map) {
    return RecentTransaction(
      id: map['id'] as int,
      customerName: (map['customer_name'] as String?) ?? 'Unknown',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      paidAt: DateTime.tryParse((map['paid_at'] as String?) ?? '') ??
          DateTime.now(),
      paymentMethod: map['payment_method'] as String?,
    );
  }
}
