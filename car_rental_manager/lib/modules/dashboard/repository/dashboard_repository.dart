import '../../../core/database/database_helper.dart';
import '../data/dashboard_local_data_source.dart';
import '../models/dashboard_state.dart';

/// Loads dashboard data from SQLite (empty snapshot on web).
class DashboardRepository {
  DashboardRepository(this._helper);

  final DatabaseHelper _helper;

  Future<DashboardState> loadDashboard() async {
    final db = await _helper.databaseOrNull;
    if (db == null) {
      return DashboardState.empty;
    }

    final source = DashboardLocalDataSource(db);
    final stats = await source.fetchStats();
    final recentCustomers = await source.fetchRecentCustomers();
    final recentTransactions = await source.fetchRecentTransactions();

    return DashboardState(
      stats: stats,
      recentCustomers: recentCustomers,
      recentTransactions: recentTransactions,
    );
  }
}
