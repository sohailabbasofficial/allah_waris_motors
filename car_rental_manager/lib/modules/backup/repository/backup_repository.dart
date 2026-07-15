import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../models/backup_file_info.dart';
import '../models/backup_state.dart';
import '../models/backup_status.dart';
import '../services/backup_notification_service.dart';
import '../services/connectivity_service.dart';
import '../services/database_backup_service.dart';
import '../services/google_drive_service.dart';

class BackupRepository {
  BackupRepository({
    required SharedPreferences prefs,
    required GoogleDriveService driveService,
    required DatabaseBackupService databaseBackupService,
    required ConnectivityService connectivityService,
    required BackupNotificationService notificationService,
  })  : _prefs = prefs,
        _drive = driveService,
        _dbBackup = databaseBackupService,
        _connectivity = connectivityService,
        _notifications = notificationService;

  final SharedPreferences _prefs;
  final GoogleDriveService _drive;
  final DatabaseBackupService _dbBackup;
  final ConnectivityService _connectivity;
  final BackupNotificationService _notifications;

  Future<BackupState> loadState() async {
    await _drive.initialize();
    final account = _drive.currentAccount;
    final lastMs = _prefs.getInt(AppConstants.keyLastBackupAt);
    return BackupState(
      isInitialized: true,
      isSignedIn: account != null,
      accountEmail: account?.email ??
          _prefs.getString(AppConstants.keyGoogleAccountEmail),
      accountDisplayName: account?.displayName ??
          _prefs.getString(AppConstants.keyGoogleAccountDisplayName),
      autoBackupEnabled:
          _prefs.getBool(AppConstants.keyAutoBackupEnabled) ?? false,
      autoBackupHour: _prefs.getInt(AppConstants.keyAutoBackupHour) ?? 21,
      autoBackupMinute: _prefs.getInt(AppConstants.keyAutoBackupMinute) ?? 0,
      lastBackupAt: lastMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMs),
      lastBackupStatus: BackupStatusX.fromStorage(
        _prefs.getString(AppConstants.keyLastBackupStatus),
      ),
      lastBackupSizeBytes:
          _prefs.getInt(AppConstants.keyLastBackupSize) ?? 0,
    );
  }

  Future<BackupState> signIn() async {
    await _ensureOnline();
    final account = await _drive.signIn();
    await _prefs.setString(AppConstants.keyGoogleAccountEmail, account.email);
    if (account.displayName != null) {
      await _prefs.setString(
        AppConstants.keyGoogleAccountDisplayName,
        account.displayName!,
      );
    }
    return loadState();
  }

  Future<BackupState> disconnect() async {
    await _drive.disconnect();
    await _prefs.remove(AppConstants.keyGoogleAccountEmail);
    await _prefs.remove(AppConstants.keyGoogleAccountDisplayName);
    return loadState();
  }

  Future<void> setAutoBackupEnabled(bool enabled) async {
    await _prefs.setBool(AppConstants.keyAutoBackupEnabled, enabled);
  }

  Future<void> setAutoBackupTime(int hour, int minute) async {
    await _prefs.setInt(AppConstants.keyAutoBackupHour, hour);
    await _prefs.setInt(AppConstants.keyAutoBackupMinute, minute);
  }

  Future<BackupState> backupNow({
    bool skipIfUnchanged = false,
    bool interactive = true,
    bool notify = false,
    void Function(String message, double? progress)? onProgress,
  }) async {
    await _ensureOnline();
    if (_drive.currentAccount == null &&
        (_prefs.getString(AppConstants.keyGoogleAccountEmail)?.isEmpty ??
            true)) {
      throw GoogleAuthException('Sign in with Google before backing up.');
    }

    // Ensure we have an active session / Drive scopes.
    if (_drive.currentAccount == null) {
      await _drive.signIn();
    }

    final fingerprint = await _dbBackup.fingerprint();
    final previous =
        _prefs.getString(AppConstants.keyLastBackupFingerprint);
    if (skipIfUnchanged &&
        previous != null &&
        previous == fingerprint &&
        _prefs.getString(AppConstants.keyLastBackupStatus) ==
            BackupStatus.success.name) {
      await _persistResult(
        status: BackupStatus.skipped,
        sizeBytes: await _dbBackup.databaseSizeBytes(),
        fingerprint: fingerprint,
      );
      if (notify) {
        await _notifications.notifyBackupResult(
          success: true,
          message: 'Automatic backup skipped — no data changes.',
        );
      }
      return loadState();
    }

    onProgress?.call('Preparing database…', 0.1);
    final dbFile = await _dbBackup.databaseFile;
    final dbBytes = await dbFile.readAsBytes();
    final settingsBytes = await _dbBackup.exportSettingsBytes();

    onProgress?.call('Uploading database…', 0.35);
    final uploaded = await _drive.uploadBytes(
      fileName: AppConstants.driveBackupDbFileName,
      bytes: dbBytes,
      interactive: interactive,
      onProgress: (p) => onProgress?.call('Uploading database…', 0.35 + p * 0.4),
    );

    onProgress?.call('Uploading settings…', 0.8);
    await _drive.uploadBytes(
      fileName: AppConstants.driveBackupSettingsFileName,
      bytes: settingsBytes,
      interactive: interactive,
    );

    await _persistResult(
      status: BackupStatus.success,
      sizeBytes: uploaded.sizeBytes,
      fingerprint: fingerprint,
      at: uploaded.modifiedTime,
    );

    if (notify) {
      await _notifications.notifyBackupResult(
        success: true,
        message: 'Cloud backup completed successfully.',
      );
    }

    onProgress?.call('Backup complete', 1);
    return loadState();
  }

  Future<List<BackupFileInfo>> listRemoteBackups({
    bool interactive = true,
  }) async {
    await _ensureOnline();
    if (_drive.currentAccount == null) {
      await _drive.signIn();
    }
    final files = await _drive.listBackupFiles(interactive: interactive);
    return files
        .where(
          (f) =>
              f.name == AppConstants.driveBackupDbFileName ||
              f.name.endsWith('.db'),
        )
        .toList();
  }

  Future<void> restoreFromDrive({
    required BackupFileInfo file,
    void Function(String message, double? progress)? onProgress,
  }) async {
    await _ensureOnline();
    if (_drive.currentAccount == null) {
      await _drive.signIn();
    }

    onProgress?.call('Downloading backup…', 0.15);
    final bytes = await _drive.downloadFile(
      file.id,
      interactive: true,
      onProgress: (p) =>
          onProgress?.call('Downloading backup…', 0.15 + p * 0.45),
    );

    onProgress?.call('Validating backup…', 0.65);
    await _dbBackup.validateDatabaseBytes(bytes);

    onProgress?.call('Restoring database…', 0.8);
    await _dbBackup.restoreDatabaseBytes(bytes);

    // Best-effort settings restore from sibling JSON.
    try {
      final siblings = await _drive.listBackupFiles(interactive: false);
      final settingsMatches = siblings.where(
        (f) => f.name == AppConstants.driveBackupSettingsFileName,
      );
      if (settingsMatches.isNotEmpty) {
        onProgress?.call('Restoring settings…', 0.92);
        final settingsBytes = await _drive.downloadFile(
          settingsMatches.first.id,
          interactive: false,
        );
        await _dbBackup.importSettingsBytes(settingsBytes);
      }
    } catch (_) {
      // Database restore already succeeded; settings are optional.
    }

    await _persistResult(
      status: BackupStatus.success,
      sizeBytes: bytes.length,
      fingerprint: await _dbBackup.fingerprint(),
    );
    onProgress?.call('Restore complete', 1);
  }

  /// Runs automatic backup once per day after the configured time.
  Future<BackupState?> maybeRunAutomaticBackup() async {
    final enabled = _prefs.getBool(AppConstants.keyAutoBackupEnabled) ?? false;
    if (!enabled) return null;
    if (_drive.currentAccount == null &&
        (_prefs.getString(AppConstants.keyGoogleAccountEmail)?.isEmpty ??
            true)) {
      return null;
    }

    final now = DateTime.now();
    final hour = _prefs.getInt(AppConstants.keyAutoBackupHour) ?? 21;
    final minute = _prefs.getInt(AppConstants.keyAutoBackupMinute) ?? 0;
    final scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isBefore(scheduled)) return null;

    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_prefs.getString(AppConstants.keyLastAutoBackupDay) == dayKey) {
      return null;
    }

    try {
      final state = await backupNow(
        skipIfUnchanged: true,
        interactive: false,
        notify: true,
      );
      await _prefs.setString(AppConstants.keyLastAutoBackupDay, dayKey);
      return state;
    } catch (e) {
      await _persistResult(
        status: BackupStatus.failed,
        sizeBytes: _prefs.getInt(AppConstants.keyLastBackupSize) ?? 0,
        fingerprint:
            _prefs.getString(AppConstants.keyLastBackupFingerprint) ?? '',
      );
      await _notifications.notifyBackupResult(
        success: false,
        message: 'Automatic backup failed: $e',
      );
      await _prefs.setString(AppConstants.keyLastAutoBackupDay, dayKey);
      return loadState();
    }
  }

  Future<void> _persistResult({
    required BackupStatus status,
    required int sizeBytes,
    required String fingerprint,
    DateTime? at,
  }) async {
    await _prefs.setInt(
      AppConstants.keyLastBackupAt,
      (at ?? DateTime.now()).millisecondsSinceEpoch,
    );
    await _prefs.setString(AppConstants.keyLastBackupStatus, status.name);
    await _prefs.setInt(AppConstants.keyLastBackupSize, sizeBytes);
    await _prefs.setString(AppConstants.keyLastBackupFingerprint, fingerprint);
  }

  Future<void> _ensureOnline() async {
    final online = await _connectivity.hasInternet();
    if (!online) {
      throw GoogleDriveException(
        'No internet connection. Connect to the network and try again.',
      );
    }
  }
}
