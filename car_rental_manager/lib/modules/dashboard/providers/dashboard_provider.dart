import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../models/dashboard_state.dart';
import '../repository/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(databaseHelperProvider));
});

/// Async dashboard snapshot. Invalidate / refresh to reload from SQLite.
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardState>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardState> {
  @override
  Future<DashboardState> build() {
    return ref.read(dashboardRepositoryProvider).loadDashboard();
  }

  /// Manual refresh used by AppBar button and pull-to-refresh.
  Future<void> refresh() async {
    final previous = state;
    state = const AsyncLoading<DashboardState>().copyWithPrevious(previous);
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).loadDashboard(),
    );
  }
}
