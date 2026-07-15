import 'package:sqflite/sqflite.dart';

import '../app_database.dart';
import '../models/settings_model.dart';
import '../tables/settings_table.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<Database?> get _databaseOrNull => _db.databaseOrNull;

  Future<SettingsModel> getSettings() async {
    final db = await _databaseOrNull;
    if (db == null) {
      return SettingsModel(
        id: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final rows = await db.query(SettingsTable.name, limit: 1);
    if (rows.isEmpty) {
      final now = DateTime.now();
      final id = await db.insert(SettingsTable.name, {
        SettingsTable.fingerprintEnabled: 0,
        SettingsTable.themeMode: 'light',
        SettingsTable.autoBackupEnabled: 0,
        SettingsTable.backupTime: '21:00',
        SettingsTable.createdAt: now.toIso8601String(),
        SettingsTable.updatedAt: now.toIso8601String(),
      });
      return SettingsModel(
        id: id,
        themeMode: 'light',
        backupTime: '21:00',
        createdAt: now,
        updatedAt: now,
      );
    }
    return SettingsModel.fromMap(rows.first);
  }

  Future<SettingsModel> updateSettings(SettingsModel settings) async {
    final db = await _databaseOrNull;
    if (db == null) return settings;

    final updated = settings.copyWith(updatedAt: DateTime.now());
    final map = updated.toMap();
    map.remove('id');

    await db.update(
      SettingsTable.name,
      map,
      where: 'id = ?',
      whereArgs: [updated.id],
    );
    return getSettings();
  }

  Future<void> setThemeMode(String mode) async {
    final current = await getSettings();
    await updateSettings(current.copyWith(themeMode: mode));
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    final current = await getSettings();
    await updateSettings(current.copyWith(fingerprintEnabled: enabled));
  }

  Future<void> setAppPinHash(String? hash) async {
    final current = await getSettings();
    await updateSettings(
      current.copyWith(appPin: hash, clearAppPin: hash == null),
    );
  }

  Future<void> setAutoBackup({
    required bool enabled,
    String? backupTime,
  }) async {
    final current = await getSettings();
    await updateSettings(
      current.copyWith(
        autoBackupEnabled: enabled,
        backupTime: backupTime ?? current.backupTime,
      ),
    );
  }

  Future<void> setLastBackup(DateTime? at) async {
    final current = await getSettings();
    await updateSettings(
      current.copyWith(lastBackup: at, clearLastBackup: at == null),
    );
  }
}
