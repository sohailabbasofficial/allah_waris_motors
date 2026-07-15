import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../providers/shared_preferences_provider.dart';

/// Supported app languages.
enum AppLanguage {
  english('en'),
  urdu('ur');

  const AppLanguage(this.code);
  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'ur':
        return AppLanguage.urdu;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}

/// Persisted app language. Default: English.
final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(AppConstants.keyLocale) ?? 'en';
    return AppLanguage.fromCode(code).locale;
  }

  AppLanguage get currentLanguage => AppLanguage.fromCode(state.languageCode);

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(AppConstants.keyLocale, language.code);
    state = language.locale;
  }
}
