import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/shared_preferences_provider.dart';

const _lightDefaultMigratedKey = 'appearance_default_light_v1';

/// Persisted [ThemeMode] (light / dark / system).
/// Product default is light.
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    if (prefs.getBool(_lightDefaultMigratedKey) != true) {
      final current = prefs.getString(AppConstants.keyThemeMode);
      if (current == null || current == 'system') {
        Future.microtask(() async {
          await prefs.setString(AppConstants.keyThemeMode, 'light');
          await prefs.setBool(_lightDefaultMigratedKey, true);
        });
        return ThemeMode.light;
      }
      Future.microtask(() async {
        await prefs.setBool(_lightDefaultMigratedKey, true);
      });
    }

    final raw = prefs.getString(AppConstants.keyThemeMode) ?? 'light';
    return _fromString(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.keyThemeMode, _toString(mode));
    await prefs.setBool(_lightDefaultMigratedKey, true);
    state = mode;
  }

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
