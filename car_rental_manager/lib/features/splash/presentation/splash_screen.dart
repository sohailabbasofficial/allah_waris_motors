import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/splash_provider.dart';

/// Splash → create PIN (first launch) or login (PIN exists).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(splashNavigationProvider, (previous, next) {
      next.whenData((_) {
        final hasPin = ref.read(hasPinProvider);
        final route = hasPin ? AppRoutes.login : AppRoutes.createPin;
        Navigator.of(context).pushReplacementNamed(route);
      });
    });

    ref.watch(splashNavigationProvider);

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_car_rounded,
                size: 96,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}