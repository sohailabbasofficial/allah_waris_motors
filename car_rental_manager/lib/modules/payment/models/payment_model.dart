/// Payment entity linked to a transaction (and customer via join).
class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.transactionId,
    required this.customerId,
    required this.customerName,
    required this.paymentDate,
    required this.paymentAmount,
    this.remainingBalance = 0,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int transactionId;
  final int customerId;
  final String customerName;
  final DateTime paymentDate;
  final double paymentAmount;

  /// Remaining amount on the linked transaction after this payment context.
  final double remainingBalance;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory PaymentModel.fromMap(Map<String, Object?> map) {
    return PaymentModel(
      id: map['id'] as int,
      transactionId: map['transaction_id'] as int,
      customerId: map['customer_id'] as int? ?? 0,
      customerName: (map['customer_name'] as String?) ?? 'Unknown',
      paymentDate:
          DateTime.tryParse((map['payment_date'] as String?) ?? '') ??
              DateTime.now(),
      paymentAmount: (map['payment_amount'] as num?)?.toDouble() ?? 0,
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'transaction_id': transactionId,
      'payment_amount': paymentAmount,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toMap(),
        'customer_id': customerId,
        'customer_name': customerName,
        'remaining_balance': remainingBalance,
      };

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel.fromMap(Map<String, Object?>.from(json));
  }

  PaymentModel copyWith({
    int? id,
    int? transactionId,
    int? customerId,
    String? customerName,
    DateTime? paymentDate,
    double? paymentAmount,
    double? remainingBalance,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
