/// Payment entity linked to a customer.
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.paymentDate,
    required this.paymentAmount,
    required this.remainingBalance,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int customerId;
  final String customerName;
  final DateTime paymentDate;
  final double paymentAmount;
  final double remainingBalance;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PaymentModel.fromMap(Map<String, Object?> map) {
    return PaymentModel(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      customerName: (map['customer_name'] as String?) ?? 'Unknown',
      paymentDate:
          DateTime.tryParse((map['payment_date'] as String?) ?? '') ??
              DateTime.now(),
      paymentAmount: (map['payment_amount'] as num?)?.toDouble() ?? 0,
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }
}
