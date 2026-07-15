enum BackupStatus { idle, success, failed, skipped, inProgress }

extension BackupStatusX on BackupStatus {
  String get label {
    switch (this) {
      case BackupStatus.idle:
        return 'Not backed up';
      case BackupStatus.success:
        return 'Success';
      case BackupStatus.failed:
        return 'Failed';
      case BackupStatus.skipped:
        return 'Skipped (no changes)';
      case BackupStatus.inProgress:
        return 'In progress';
    }
  }

  static BackupStatus fromStorage(String? value) {
    return BackupStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => BackupStatus.idle,
    );
  }
}
