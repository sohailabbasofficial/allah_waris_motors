import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/database_provider.dart';
import '../../../providers/shared_preferences_provider.dart';
import '../../customer/providers/customer_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../reports/providers/reports_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../models/backup_file_info.dart';
import '../models/backup_state.dart';
import '../models/backup_status.dart';
import '../repository/backup_repository.dart';
import '../services/backup_notification_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_backup_service.dart';
import '../services/google_drive_service.dart';

export 'data_change_bus.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final service = GoogleDriveService();
  ref.onDispose(service.dispose);
  return service;
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final backupNotificationServiceProvider =
    Provider<BackupNotificationService>((ref) {
  return BackupNotificationService();
});

final databaseBackupServiceProvider = Provider<DatabaseBackupService>((ref) {
  return DatabaseBackupService(
    ref.watch(databaseHelperProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    prefs: ref.watch(sharedPreferencesProvider),
    driveService: ref.watch(googleDriveServiceProvider),
    databaseBackupService: ref.watch(databaseBackupServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    notificationService: ref.watch(backupNotificationServiceProvider),
  );
});

final backupProvider =
    AsyncNotifierProvider<BackupNotifier, BackupState>(BackupNotifier.new);

/// Alias matching requested naming.
typedef BackupProvider = BackupNotifier;

class BackupNotifier extends AsyncNotifier<BackupState> {
  Timer? _syncDebounce;

  @override
  Future<BackupState> build() async {
    ref.onDispose(() {
      _syncDebounce?.cancel();
    });
    if (kIsWeb) {
      return const BackupState(
        isInitialized: true,
        errorMessage: 'Backup & Restore requires Android, iOS, or desktop.',
      );
    }
    final repo = ref.read(backupRepositoryProvider);
    final state = await repo.loadState();
    // Fire-and-forget auto backup check after load.
    Future.microtask(maybeRunAutomaticBackup);
    return state;
  }

  BackupRepository get _repo => ref.read(backupRepositoryProvider);

  /// Debounced Drive sync after local customer/ledger/payment changes.
  void scheduleSyncAfterLocalChange() {
    if (kIsWeb) return;
    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(seconds: 4), () {
      unawaited(syncAfterLocalChange());
    });
  }

  Future<void> syncAfterLocalChange() async {
    if (kIsWeb) return;
    final current = state.valueOrNull;
    if (current?.isBusy == true) {
      // Retry shortly if a manual backup/restore is running.
      scheduleSyncAfterLocalChange();
      return;
    }
    try {
      final result = await _repo.syncAfterLocalChange();
      if (result != null) {
        state = AsyncData(result);
      }
    } catch (_) {
      // Best-effort background sync — failures must not block the UI.
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading<BackupState>().copyWithPrevious(state);
    state = await AsyncValue.guard(_repo.loadState);
  }

  Future<void> connectGoogle() async {
    await _runBusy((_) => _repo.signIn());
  }

  Future<void> disconnectGoogle() async {
    await _runBusy((_) => _repo.disconnect());
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _repo.setAutoBackupEnabled(enabled);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(autoBackupEnabled: enabled));
    }
  }

  Future<void> setAutoBackupTime(int hour, int minute) async {
    await _repo.setAutoBackupTime(hour, minute);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(autoBackupHour: hour, autoBackupMinute: minute),
      );
    }
  }

  Future<void> backupNow({bool skipIfUnchanged = false}) async {
    await _runBusy(
      (onProgress) => _repo.backupNow(
        skipIfUnchanged: skipIfUnchanged,
        interactive: true,
        notify: false,
        onProgress: onProgress,
      ),
    );
  }

  Future<void> loadRemoteBackups() async {
    await _runBusy((_) async {
      final files = await _repo.listRemoteBackups();
      final current = await _repo.loadState();
      return current.copyWith(availableBackups: files);
    });
  }

  Future<void> restore(BackupFileInfo file) async {
    await _runBusy((onProgress) async {
      await _repo.restoreFromDrive(file: file, onProgress: onProgress);
      // Force SQLite + all modules to reload from the restored file.
      ref.invalidate(databaseProvider);
      _invalidateAppData();
      return _repo.loadState();
    });
  }

  /// One-tap: restore the newest Google Drive backup into local data.
  Future<int> restoreLatestFromCloud() async {
    var customers = 0;
    await _runBusy((onProgress) async {
      customers = await _repo.restoreLatestFromCloud(onProgress: onProgress);
      ref.invalidate(databaseProvider);
      _invalidateAppData();
      return _repo.loadState();
    });
    return customers;
  }

  Future<void> maybeRunAutomaticBackup() async {
    if (kIsWeb) return;
    final current = state.valueOrNull;
    if (current?.isBusy == true) return;
    try {
      final result = await _repo.maybeRunAutomaticBackup();
      if (result != null) {
        state = AsyncData(result);
      }
    } catch (_) {
      // Auto backup failures are persisted + notified inside repository.
    }
  }

  Future<void> _runBusy(
    Future<BackupState> Function(
      void Function(String message, double? progress) onProgress,
    ) action,
  ) async {
    final previous = state.valueOrNull ?? const BackupState();
    state = AsyncData(
      previous.copyWith(
        isBusy: true,
        lastBackupStatus: BackupStatus.inProgress,
        clearError: true,
        progressMessage: 'Starting…',
      ),
    );
    try {
      final next = await action((message, progress) {
        final latest = state.valueOrNull ?? previous;
        state = AsyncData(
          latest.copyWith(
            isBusy: true,
            progressMessage: progress == null
                ? message
                : '$message (${(progress * 100).round()}%)',
          ),
        );
      });
      state = AsyncData(
        next.copyWith(isBusy: false, clearProgress: true, clearError: true),
      );
    } catch (e) {
      final latest = state.valueOrNull ?? previous;
      state = AsyncData(
        latest.copyWith(
          isBusy: false,
          clearProgress: true,
          errorMessage: e.toString(),
          lastBackupStatus: BackupStatus.failed,
        ),
      );
      rethrow;
    }
  }

  void _invalidateAppData() {
    ref.invalidate(dashboardProvider);
    ref.invalidate(customerListProvider);
    ref.invalidate(transactionListProvider);
    ref.invalidate(paymentListProvider);
    ref.invalidate(outstandingCustomersProvider);
    ref.invalidate(reportsUiProvider);
  }
}
