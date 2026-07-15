import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/auth/authorized_google_account.dart';
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
    await _syncAuthorizedSession();
    final account = _drive.currentAccount;
    final authorized =
        account != null && AuthorizedGoogleAccount.isAuthorized(account.email);
    final lastMs = _prefs.getInt(AppConstants.keyLastBackupAt);
    return BackupState(
      isInitialized: true,
      isSignedIn: authorized,
      accountEmail: authorized
          ? account.email
          : null,
      accountDisplayName: authorized
          ? (account.displayName ??
              _prefs.getString(AppConstants.keyGoogleAccountDisplayName))
          : null,
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

  /// True when the workshop owner's Google account is currently signed in.
  Future<bool> isAuthorizedSession() async {
    await _drive.initialize();
    await _syncAuthorizedSession();
    final account = _drive.currentAccount;
    return account != null &&
        AuthorizedGoogleAccount.isAuthorized(account.email);
  }

  Future<void> _syncAuthorizedSession() async {
    final account = _drive.currentAccount;
    if (account == null) {
      final flagged =
          _prefs.getBool(AppConstants.keyAuthorizedGoogleSignedIn) ?? false;
      if (flagged) {
        // Lightweight restore failed — require a fresh Google Sign-In.
        await _clearAuthorizedPrefs();
      }
      return;
    }
    if (!AuthorizedGoogleAccount.isAuthorized(account.email)) {
      await _drive.signOut();
      await _clearAuthorizedPrefs();
      return;
    }
    await _prefs.setBool(AppConstants.keyAuthorizedGoogleSignedIn, true);
    await _prefs.setString(AppConstants.keyGoogleAccountEmail, account.email);
    if (account.displayName != null) {
      await _prefs.setString(
        AppConstants.keyGoogleAccountDisplayName,
        account.displayName!,
      );
    }
  }

  Future<void> _clearAuthorizedPrefs() async {
    await _prefs.setBool(AppConstants.keyAuthorizedGoogleSignedIn, false);
    await _prefs.remove(AppConstants.keyGoogleAccountEmail);
    await _prefs.remove(AppConstants.keyGoogleAccountDisplayName);
  }

  Future<BackupState> signIn() async {
    await _ensureOnline();
    final account = await _drive.signIn();
    // Defense in depth — Drive service already enforces this.
    if (!AuthorizedGoogleAccount.isAuthorized(account.email)) {
      await _drive.signOut();
      await _clearAuthorizedPrefs();
      throw GoogleAuthException(AuthorizedGoogleAccount.accessDeniedMessage);
    }
    await _prefs.setBool(AppConstants.keyAuthorizedGoogleSignedIn, true);
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
    await _clearAuthorizedPrefs();
    // Biometric unlock is only valid after an authorized Google Sign-In.
    await _prefs.setBool(AppConstants.keyBiometricEnabled, false);
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
    /// When true, allow uploading even if there are 0 customers (e.g. after deletes).
    bool allowEmpty = false,
    /// When false, overwrite the stable latest Drive file instead of a new stamp.
    bool createNewVersion = true,
    bool bypassRestoreQuietWindow = false,
    void Function(String message, double? progress)? onProgress,
  }) async {
    await _ensureOnline();
    await _ensureAuthorizedForCloud();

    final localCustomers = await _dbBackup.customerCount();
    // Never upload an empty install via manual/daily backup — would wipe Drive.
    if (localCustomers == 0 && !allowEmpty) {
      throw GoogleDriveException(
        'Local data is empty. Restore your Drive backup first. '
        'Backing up now would erase your cloud data.',
      );
    }

    if (!bypassRestoreQuietWindow && _isWithinRestoreQuietWindow()) {
      throw GoogleDriveException(
        'Backup paused for a short time after restore. '
        'Wait a few minutes, then try again.',
      );
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

    final fileName = createNewVersion
        ? _timestampedBackupDbName()
        : AppConstants.driveBackupDbFileName;

    onProgress?.call('Uploading database…', 0.35);
    final uploaded = await _drive.uploadBytes(
      fileName: fileName,
      bytes: dbBytes,
      interactive: interactive,
      overwriteExisting: !createNewVersion,
      onProgress: (p) => onProgress?.call('Uploading database…', 0.35 + p * 0.4),
    );

    onProgress?.call('Uploading settings…', 0.8);
    await _drive.uploadBytes(
      fileName: AppConstants.driveBackupSettingsFileName,
      bytes: settingsBytes,
      interactive: interactive,
      overwriteExisting: true,
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

  /// Silent sync used after local add/edit/delete (updates the latest Drive file).
  Future<BackupState?> syncAfterLocalChange() async {
    if (!await isAuthorizedSession()) return null;
    try {
      final online = await _connectivity.hasInternet();
      if (!online) return null;
      return backupNow(
        skipIfUnchanged: true,
        interactive: false,
        notify: false,
        allowEmpty: true,
        createNewVersion: false,
        bypassRestoreQuietWindow: true,
      );
    } catch (_) {
      return null;
    }
  }

  String _timestampedBackupDbName() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${AppConstants.driveBackupDbPrefix}_'
        '${n.year}${two(n.month)}${two(n.day)}_'
        '${two(n.hour)}${two(n.minute)}${two(n.second)}.db';
  }

  bool _isWithinRestoreQuietWindow() {
    final ms = _prefs.getInt(AppConstants.keyLastRestoreAt);
    if (ms == null) return false;
    final ago = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms));
    return ago < const Duration(hours: 6);
  }

  Future<List<BackupFileInfo>> listRemoteBackups({
    bool interactive = true,
  }) async {
    await _ensureOnline();
    await _ensureAuthorizedForCloud();
    final files = await _drive.listBackupFiles(interactive: interactive);
    final dbFiles = files
        .where(
          (f) =>
              f.name == AppConstants.driveBackupDbFileName ||
              (f.name.startsWith(AppConstants.driveBackupDbPrefix) &&
                  f.name.endsWith('.db')),
        )
        .toList()
      ..sort((a, b) => b.modifiedTime.compareTo(a.modifiedTime));
    return dbFiles;
  }

  /// One-tap recover: download the newest Drive backup into local SQLite.
  /// Returns how many customers were restored.
  Future<int> restoreLatestFromCloud({
    void Function(String message, double? progress)? onProgress,
  }) async {
    onProgress?.call('Looking for cloud backup…', 0.05);
    final files = await listRemoteBackups(interactive: true);
    if (files.isEmpty) {
      throw GoogleDriveException(
        'No backup found on Google Drive. '
        'Open Drive Trash and restore any deleted backup first.',
      );
    }
    final latest = files.first;
    onProgress?.call('Found ${latest.name}', 0.1);
    await restoreFromDrive(file: latest, onProgress: onProgress);
    return _dbBackup.customerCount();
  }

  Future<void> restoreFromDrive({
    required BackupFileInfo file,
    void Function(String message, double? progress)? onProgress,
  }) async {
    await _ensureOnline();
    await _ensureAuthorizedForCloud();

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
    final restoredCustomers = await _dbBackup.restoreDatabaseBytes(bytes);

    // Best-effort settings restore from sibling JSON (never touch Drive DB files).
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

    await _prefs.setInt(
      AppConstants.keyLastRestoreAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    // Pause auto-backup so an empty/stale run cannot overwrite Drive after restore.
    await _prefs.setBool(AppConstants.keyAutoBackupEnabled, false);

    await _persistResult(
      status: BackupStatus.success,
      sizeBytes: bytes.length,
      fingerprint: await _dbBackup.fingerprint(),
    );
    onProgress?.call(
      'Restore complete ($restoredCustomers customers)',
      1,
    );
  }

  Future<void> _ensureAuthorizedForCloud() async {
    if (!await isAuthorizedSession()) {
      if (_drive.currentAccount == null) {
        await _drive.signIn();
      }
      if (!await isAuthorizedSession()) {
        throw GoogleAuthException(AuthorizedGoogleAccount.accessDeniedMessage);
      }
    }
  }

  /// Runs automatic backup once per day after the configured time.
  Future<BackupState?> maybeRunAutomaticBackup() async {
    final enabled = _prefs.getBool(AppConstants.keyAutoBackupEnabled) ?? false;
    if (!enabled) return null;
    if (!await isAuthorizedSession()) {
      return null;
    }
    // Never auto-upload an empty database (wipes cloud data after reinstall).
    if (await _dbBackup.customerCount() == 0) {
      return null;
    }
    if (_isWithinRestoreQuietWindow()) {
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
