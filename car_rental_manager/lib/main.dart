import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/locale_provider.dart';
import 'features/settings/providers/theme_provider.dart';
import 'l10n/app_localizations.dart';
import 'modules/backup/providers/backup_provider.dart';
import 'modules/backup/widgets/backup_lifecycle_listener.dart';
import 'providers/shared_preferences_provider.dart';
import 'routes/app_routes.dart';

TextScaler _clampedTextScaler(TextScaler incoming) {
  return incoming.clamp(minScaleFactor: 0.90, maxScaleFactor: 1.20);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    await DatabaseHelper.instance.database;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AllahWarisMotorsApp(),
    ),
  );
}

/// Root widget for Allah Waris Motors.
class AllahWarisMotorsApp extends ConsumerStatefulWidget {
  const AllahWarisMotorsApp({super.key});

  @override
  ConsumerState<AllahWarisMotorsApp> createState() =>
      _AllahWarisMotorsAppState();
}

class _AllahWarisMotorsAppState extends ConsumerState<AllahWarisMotorsApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(backupNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return BackupLifecycleListener(
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: _clampedTextScaler(media.textScaler),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        initialRoute: AppRoutes.splash,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
