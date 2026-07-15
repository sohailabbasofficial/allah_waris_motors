/// SQL DDL and metadata for the `settings` table (single-row app settings).
class SettingsTable {
  SettingsTable._();

  static const String name = 'settings';

  static const String id = 'id';
  static const String appPin = 'app_pin';
  static const String fingerprintEnabled = 'fingerprint_enabled';
  static const String themeMode = 'theme_mode';
  static const String backupTime = 'backup_time';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String lastBackup = 'last_backup';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';

  static const String createSql = '''
CREATE TABLE IF NOT EXISTS settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  app_pin TEXT,
  fingerprint_enabled INTEGER NOT NULL DEFAULT 0,
  theme_mode TEXT NOT NULL DEFAULT 'system',
  backup_time TEXT,
  auto_backup_enabled INTEGER NOT NULL DEFAULT 0,
  last_backup TEXT,
  created_at TEXT,
  updated_at TEXT
)
''';

  static const List<String> indexes = <String>[];
}
