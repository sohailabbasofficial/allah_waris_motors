import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/database_helper.dart';

class DatabaseValidationException implements Exception {
  DatabaseValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Local SQLite + SharedPreferences packaging for backup/restore.
class DatabaseBackupService {
  DatabaseBackupService(
    this._helper, {
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final DatabaseHelper _helper;
  final SharedPreferences _prefs;

  Future<File> get databaseFile async {
    if (kIsWeb) {
      throw UnsupportedError('Backup is not supported on web.');
    }
    final path = await _helper.databaseFilePath;
    return File(path);
  }

  Future<int> databaseSizeBytes() async {
    final file = await databaseFile;
    if (!await file.exists()) return 0;
    return file.length();
  }

  Future<String> fingerprint() async {
    final file = await databaseFile;
    if (!await file.exists()) return 'missing';
    final stat = await file.stat();
    return '${stat.modified.millisecondsSinceEpoch}:${stat.size}';
  }

  Future<Map<String, Object?>> exportSettingsMap() async {
    final keys = _prefs.getKeys();
    final map = <String, Object?>{};
    for (final key in keys) {
      map[key] = _prefs.get(key);
    }
    return map;
  }

  Future<List<int>> exportSettingsBytes() async {
    final map = await exportSettingsMap();
    return utf8.encode(jsonEncode(map));
  }

  Future<void> importSettingsBytes(List<int> bytes) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw DatabaseValidationException('Settings backup is corrupted.');
    }
    for (final entry in decoded.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is int) {
        await _prefs.setInt(key, value);
      } else if (value is double) {
        await _prefs.setDouble(key, value);
      } else if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is List) {
        await _prefs.setStringList(
          key,
          value.map((e) => e.toString()).toList(),
        );
      }
    }
  }

  /// Validates that [bytes] form a readable SQLite DB with required tables.
  Future<void> validateDatabaseBytes(List<int> bytes) async {
    if (bytes.length < 16) {
      throw DatabaseValidationException('Backup file is empty or corrupted.');
    }
    final header = String.fromCharCodes(bytes.take(15));
    if (!header.startsWith('SQLite format')) {
      throw DatabaseValidationException(
        'Selected file is not a valid SQLite database.',
      );
    }

    final tempDir = await getTemporaryDirectory();
    final tempPath = p.join(
      tempDir.path,
      'restore_validate_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(bytes, flush: true);

    Database? db;
    try {
      db = await openDatabase(tempPath, readOnly: true);
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names = tables.map((e) => e['name'] as String).toSet();
      const required = {'customers', 'transactions', 'payments'};
      final missing = required.difference(names);
      if (missing.isNotEmpty) {
        throw DatabaseValidationException(
          'Backup is missing tables: ${missing.join(', ')}',
        );
      }
    } finally {
      await db?.close();
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  /// Replaces the live database with [bytes] after validation.
  Future<void> restoreDatabaseBytes(List<int> bytes) async {
    await validateDatabaseBytes(bytes);

    final livePath = await _helper.databaseFilePath;
    final liveFile = File(livePath);
    final tempDir = await getTemporaryDirectory();
    final stagingPath = p.join(
      tempDir.path,
      'restore_staging_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    final staging = File(stagingPath);
    await staging.writeAsBytes(bytes, flush: true);

    await _helper.close();

    final backupPath = '$livePath.bak';
    if (await liveFile.exists()) {
      await liveFile.copy(backupPath);
    }

    try {
      if (await liveFile.exists()) {
        await liveFile.delete();
      }
      await staging.copy(livePath);
      await _helper.reopen();
    } catch (e) {
      // Attempt rollback.
      final rollback = File(backupPath);
      if (await rollback.exists()) {
        if (await liveFile.exists()) {
          await liveFile.delete();
        }
        await rollback.copy(livePath);
        await _helper.reopen();
      }
      throw DatabaseValidationException('Restore failed: $e');
    } finally {
      if (await staging.exists()) {
        await staging.delete();
      }
    }
  }
}
