/// Customer with a positive remaining balance for the outstanding report.
class OutstandingCustomer {
  const OutstandingCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalAmount,
    required this.totalPaid,
    required this.remainingBalance,
  });

  final int id;
  final String name;
  final String phone;
  final double totalAmount;
  final double totalPaid;
  final double remainingBalance;

  factory OutstandingCustomer.fromMap(Map<String, Object?> map) {
    return OutstandingCustomer(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      totalAmount: (map['total_udhaar'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['total_received'] as num?)?.toDouble() ?? 0,
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble() ?? 0,
    );
  }
}

enum OutstandingSort { highestBalance, lowestBalance }
