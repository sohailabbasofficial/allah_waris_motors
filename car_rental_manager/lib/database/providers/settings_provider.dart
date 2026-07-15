import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(appDatabaseProvider));
});

final settingsProvider = FutureProvider.autoDispose<SettingsModel>((ref) async {
  return ref.watch(settingsRepositoryProvider).getSettings();
});
