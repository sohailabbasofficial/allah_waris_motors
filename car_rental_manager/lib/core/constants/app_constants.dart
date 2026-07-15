/// Application-wide constants for Allah Waris Motors.
class AppConstants {
  AppConstants._();

  static const String appName = 'Allah Waris Motors';
  static const String databaseName = 'allah_waris_motors.db';

  /// v5 migrates payments to the Payment Management schema.
  static const int databaseVersion = 5;

  static const Duration splashDuration = Duration(seconds: 2);
  static const int pinLength = 4;
  static const int maxPinAttempts = 5;
  static const Duration pinLockoutDuration = Duration(seconds: 30);
  static const String pinHashPepper = 'allah_waris_motors_pin_v1';

  static const String keyPinHash = 'security_pin_hash';
  static const String keyBiometricEnabled = 'security_biometric_enabled';
  static const String keyThemeMode = 'appearance_theme_mode';
  static const String keyFailedPinAttempts = 'security_failed_pin_attempts';
  static const String keyPinLockUntil = 'security_pin_lock_until_ms';

  /// Backup & Restore prefs.
  static const String keyGoogleAccountEmail = 'backup_google_account_email';
  static const String keyGoogleAccountDisplayName =
      'backup_google_account_display_name';
  static const String keyAutoBackupEnabled = 'backup_auto_enabled';
  static const String keyAutoBackupHour = 'backup_auto_hour';
  static const String keyAutoBackupMinute = 'backup_auto_minute';
  static const String keyLastBackupAt = 'backup_last_at_ms';
  static const String keyLastBackupStatus = 'backup_last_status';
  static const String keyLastBackupSize = 'backup_last_size_bytes';
  static const String keyLastBackupFingerprint = 'backup_last_fingerprint';
  static const String keyLastAutoBackupDay = 'backup_last_auto_day';

  /// Drive folder used for cloud backups.
  static const String driveBackupFolderName = 'Car Rental Manager Backup';
  static const String driveBackupDbFileName = 'allah_waris_motors_backup.db';
  static const String driveBackupSettingsFileName =
      'allah_waris_motors_settings.json';

  /// Optional OAuth client IDs (set after Google Cloud Console setup).
  /// Leave null to use platform defaults when configured via google-services.
  static const String? googleSignInClientId = null;
  static const String? googleSignInServerClientId = null;

  static const String currencySymbol = 'Rs.';
}
