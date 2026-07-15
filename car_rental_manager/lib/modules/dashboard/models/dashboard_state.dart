import 'dashboard_stats.dart';
import 'recent_customer.dart';
import 'recent_transaction.dart';

/// Full dashboard snapshot loaded from SQLite.
class DashboardState {
  const DashboardState({
    required this.stats,
    required this.recentCustomers,
    required this.recentTransactions,
  });

  final DashboardStats stats;
  final List<RecentCustomer> recentCustomers;
  final List<RecentTransaction> recentTransactions;

  static const empty = DashboardState(
    stats: DashboardStats.empty,
    recentCustomers: [],
    recentTransactions: [],
  );

  bool get isEmpty =>
      stats.totalCustomers == 0 &&
      recentCustomers.isEmpty &&
      recentTransactions.isEmpty;

  DashboardState copyWith({
    DashboardStats? stats,
    List<RecentCustomer>? recentCustomers,
    List<RecentTransaction>? recentTransactions,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      recentCustomers: recentCustomers ?? this.recentCustomers,
      recentTransactions: recentTransactions ?? this.recentTransactions,
    );
  }
}
