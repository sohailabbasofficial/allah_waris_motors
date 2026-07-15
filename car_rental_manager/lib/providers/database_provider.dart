import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Opens SQLite when available; null on web.
final databaseProvider = FutureProvider<Database?>((ref) async {
  return ref.watch(databaseHelperProvider).databaseOrNull;
});
