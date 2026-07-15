import 'backup_file_info.dart';
import 'backup_status.dart';

/// Snapshot of backup UI + persisted last-run metadata.
class BackupState {
  const BackupState({
    this.isInitialized = false,
    this.isSignedIn = false,
    this.accountEmail,
    this.accountDisplayName,
    this.autoBackupEnabled = false,
    this.autoBackupHour = 21,
    this.autoBackupMinute = 0,
    this.lastBackupAt,
    this.lastBackupStatus = BackupStatus.idle,
    this.lastBackupSizeBytes = 0,
    this.isBusy = false,
    this.progressMessage,
    this.errorMessage,
    this.availableBackups = const [],
  });

  final bool isInitialized;
  final bool isSignedIn;
  final String? accountEmail;
  final String? accountDisplayName;
  final bool autoBackupEnabled;
  final int autoBackupHour;
  final int autoBackupMinute;
  final DateTime? lastBackupAt;
  final BackupStatus lastBackupStatus;
  final int lastBackupSizeBytes;
  final bool isBusy;
  final String? progressMessage;
  final String? errorMessage;
  final List<BackupFileInfo> availableBackups;

  String get autoBackupTimeLabel {
    final h = autoBackupHour.toString().padLeft(2, '0');
    final m = autoBackupMinute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get lastBackupSizeLabel {
    final size = lastBackupSizeBytes;
    if (size <= 0) return '-';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  BackupState copyWith({
    bool? isInitialized,
    bool? isSignedIn,
    String? accountEmail,
    String? accountDisplayName,
    bool? autoBackupEnabled,
    int? autoBackupHour,
    int? autoBackupMinute,
    DateTime? lastBackupAt,
    BackupStatus? lastBackupStatus,
    int? lastBackupSizeBytes,
    bool? isBusy,
    String? progressMessage,
    String? errorMessage,
    List<BackupFileInfo>? availableBackups,
    bool clearAccount = false,
    bool clearError = false,
    bool clearProgress = false,
    bool clearLastBackupAt = false,
  }) {
    return BackupState(
      isInitialized: isInitialized ?? this.isInitialized,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      accountEmail: clearAccount ? null : (accountEmail ?? this.accountEmail),
      accountDisplayName: clearAccount
          ? null
          : (accountDisplayName ?? this.accountDisplayName),
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      autoBackupHour: autoBackupHour ?? this.autoBackupHour,
      autoBackupMinute: autoBackupMinute ?? this.autoBackupMinute,
      lastBackupAt:
          clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
      lastBackupStatus: lastBackupStatus ?? this.lastBackupStatus,
      lastBackupSizeBytes: lastBackupSizeBytes ?? this.lastBackupSizeBytes,
      isBusy: isBusy ?? this.isBusy,
      progressMessage:
          clearProgress ? null : (progressMessage ?? this.progressMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      availableBackups: availableBackups ?? this.availableBackups,
    );
  }
}
