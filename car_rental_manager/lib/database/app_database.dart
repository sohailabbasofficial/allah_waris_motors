import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_constants.dart';
import 'migrations.dart';

/// Application SQLite database facade (versioned schema).
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database?> get databaseOrNull async {
    if (kIsWeb) return null;
    return database;
  }

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<String> get databaseFilePath async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web.');
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return p.join(documentsDirectory.path, AppConstants.databaseName);
  }

  Future<Database> _open() async {
    final path = await databaseFilePath;
    return openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: DatabaseMigrations.onCreate,
      onUpgrade: DatabaseMigrations.onUpgrade,
      onDowngrade: DatabaseMigrations.onDowngrade,
    );
  }

  /// Runs [action] inside a SQLite transaction when the database is available.
  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  Future<Database> reopen() async {
    await close();
    return database;
  }
}
