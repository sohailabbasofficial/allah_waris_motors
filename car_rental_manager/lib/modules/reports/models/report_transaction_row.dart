/// Compact transaction row used inside daily/monthly report lists.
class ReportTransactionRow {
  const ReportTransactionRow({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.date,
    required this.description,
    required this.totalAmount,
    required this.receivedAmount,
    required this.remainingAmount,
    this.notes,
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

  factory ReportTransactionRow.fromMap(Map<String, Object?> map) {
    return ReportTransactionRow(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      customerName: (map['customer_name'] as String?) ?? '',
      date: DateTime.tryParse((map['date'] as String?) ?? '') ?? DateTime.now(),
      description: (map['description'] as String?) ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0,
      receivedAmount: (map['received_amount'] as num?)?.toDouble() ?? 0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String?,
    );
  }
}
