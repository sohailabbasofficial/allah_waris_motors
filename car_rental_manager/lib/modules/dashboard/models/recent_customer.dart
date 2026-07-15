/// Lightweight customer row for the dashboard "Recent Customers" list.
class RecentCustomer {
  const RecentCustomer({
    required this.id,
    required this.name,
    required this.phone,
    required this.remainingBalance,
  });

  final int id;
  final String name;
  final String phone;
  final double remainingBalance;

  factory RecentCustomer.fromMap(Map<String, Object?> map) {
    return RecentCustomer(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
