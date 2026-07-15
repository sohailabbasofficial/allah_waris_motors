/// Transaction entity linked to a customer.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.description,
    required this.totalAmount,
    required this.receivedAmount,
    required this.remainingAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int customerId;
  final String customerName;
  final DateTime date;
  final String description;
  final double totalAmount;
  final double receivedAmount;
  final double remainingAmount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      customerName: (map['customer_name'] as String?) ?? 'Unknown',
      date: DateTime.tryParse((map['date'] as String?) ?? '') ?? DateTime.now(),
      description: (map['description'] as String?) ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      receivedAmount: (map['received_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'customer_id': customerId,
      'date': date.toIso8601String(),
      'description': description,
      'total_amount': totalAmount,
      'received_amount': receivedAmount,
      'remaining_amount': remainingAmount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? id,
    int? customerId,
    String? customerName,
    DateTime? date,
    String? description,
    double? totalAmount,
    double? receivedAmount,
    double? remainingAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      date: date ?? this.date,
      description: description ?? this.description,
      totalAmount: totalAmount ?? this.totalAmount,
      receivedAmount: receivedAmount ?? this.receivedAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
