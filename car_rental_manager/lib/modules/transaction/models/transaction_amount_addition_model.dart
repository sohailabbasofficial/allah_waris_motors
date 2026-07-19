/// One amount-addition ledger entry for a transaction.
class TransactionAmountAdditionModel {
  const TransactionAmountAdditionModel({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.previousTotal,
    required this.newTotal,
    this.notes,
    this.addedBy,
    required this.createdAt,
  });

  final int id;
  final int transactionId;
  final double amount;
  final double previousTotal;
  final double newTotal;
  final String? notes;
  final String? addedBy;
  final DateTime createdAt;

  factory TransactionAmountAdditionModel.fromMap(Map<String, Object?> map) {
    return TransactionAmountAdditionModel(
      id: map['id'] as int,
      transactionId: map['transaction_id'] as int,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      previousTotal: (map['previous_total'] as num?)?.toDouble() ?? 0,
      newTotal: (map['new_total'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
      addedBy: map['added_by'] as String?,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'transaction_id': transactionId,
      'amount': amount,
      'previous_total': previousTotal,
      'new_total': newTotal,
      'notes': notes,
      'added_by': addedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
