/// Aggregate business statistics for the dashboard.
class DashboardStats {
  const DashboardStats({
    required this.totalCustomers,
    required this.totalUdhaar,
    required this.totalReceived,
    required this.remainingBalance,
    required this.todaysCollection,
  });

  final int totalCustomers;
  final double totalUdhaar;
  final double totalReceived;
  final double remainingBalance;
  final double todaysCollection;

  static const empty = DashboardStats(
    totalCustomers: 0,
    totalUdhaar: 0,
    totalReceived: 0,
    remainingBalance: 0,
    todaysCollection: 0,
  );

  DashboardStats copyWith({
    int? totalCustomers,
    double? totalUdhaar,
    double? totalReceived,
    double? remainingBalance,
    double? todaysCollection,
  }) {
    return DashboardStats(
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalUdhaar: totalUdhaar ?? this.totalUdhaar,
      totalReceived: totalReceived ?? this.totalReceived,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      todaysCollection: todaysCollection ?? this.todaysCollection,
    );
  }
}
