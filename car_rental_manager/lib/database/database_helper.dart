import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

/// Backward-compatible helper used by existing module repositories.
///
/// New code should prefer [AppDatabase.instance] directly.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  final AppDatabase _app = AppDatabase.instance;

  Future<Database?> get databaseOrNull => _app.databaseOrNull;

  Future<Database> get database => _app.database;

  Future<String> get databaseFilePath => _app.databaseFilePath;

  Future<T> runInTransaction<T>(
    Future<T> Function(Transaction txn) action,
  ) =>
      _app.runInTransaction(action);

  Future<void> close() => _app.close();

  Future<Database> reopen() => _app.reopen();
}
