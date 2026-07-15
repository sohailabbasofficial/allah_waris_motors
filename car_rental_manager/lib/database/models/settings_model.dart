/// App settings persisted in SQLite (`settings` table).
class SettingsModel {
  const SettingsModel({
    required this.id,
    this.appPin,
    this.fingerprintEnabled = false,
    this.themeMode = 'light',
    this.backupTime,
    this.autoBackupEnabled = false,
    this.lastBackup,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String? appPin;
  final bool fingerprintEnabled;
  final String themeMode;
  final String? backupTime;
  final bool autoBackupEnabled;
  final DateTime? lastBackup;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SettingsModel.fromMap(Map<String, Object?> map) {
    return SettingsModel(
      id: map['id'] as int? ?? 1,
      appPin: map['app_pin'] as String?,
      fingerprintEnabled: (map['fingerprint_enabled'] as num?)?.toInt() == 1,
      themeMode: (map['theme_mode'] as String?) ?? 'light',
      backupTime: map['backup_time'] as String?,
      autoBackupEnabled: (map['auto_backup_enabled'] as num?)?.toInt() == 1,
      lastBackup: DateTime.tryParse((map['last_backup'] as String?) ?? ''),
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'app_pin': appPin,
      'fingerprint_enabled': fingerprintEnabled ? 1 : 0,
      'theme_mode': themeMode,
      'backup_time': backupTime,
      'auto_backup_enabled': autoBackupEnabled ? 1 : 0,
      'last_backup': lastBackup?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  SettingsModel copyWith({
    int? id,
    String? appPin,
    bool? fingerprintEnabled,
    String? themeMode,
    String? backupTime,
    bool? autoBackupEnabled,
    DateTime? lastBackup,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAppPin = false,
    bool clearBackupTime = false,
    bool clearLastBackup = false,
  }) {
    return SettingsModel(
      id: id ?? this.id,
      appPin: clearAppPin ? null : (appPin ?? this.appPin),
      fingerprintEnabled: fingerprintEnabled ?? this.fingerprintEnabled,
      themeMode: themeMode ?? this.themeMode,
      backupTime: clearBackupTime ? null : (backupTime ?? this.backupTime),
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackup: clearLastBackup ? null : (lastBackup ?? this.lastBackup),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => toMap(includeId: true);

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel.fromMap(Map<String, Object?>.from(json));
  }
}
