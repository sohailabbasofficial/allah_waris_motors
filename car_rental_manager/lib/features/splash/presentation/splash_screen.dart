import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../modules/backup/providers/backup_provider.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/google_session_provider.dart';
import '../providers/splash_provider.dart';

/// Branded splash matching Allah Waris Motors visual identity.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  Future<void> _navigateAfterSplash(BuildContext context, WidgetRef ref) async {
    // Refresh Google session before deciding the gate.
    await ref.read(backupRepositoryProvider).loadState();
    ref.invalidate(authorizedGoogleSessionProvider);
    final authorized =
        await ref.read(authorizedGoogleSessionProvider.future);
    if (!context.mounted) return;

    if (!authorized) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.googleSignIn,
        arguments: const {'asGate': true},
      );
      return;
    }

    final hasPin = ref.read(hasPinProvider);
    Navigator.of(context).pushReplacementNamed(
      hasPin ? AppRoutes.login : AppRoutes.createPin,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(splashNavigationProvider, (previous, next) {
      next.whenData((_) {
        _navigateAfterSplash(context, ref);
      });
    });

    ref.watch(splashNavigationProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePaddingWide,
                vertical: AppSpacing.xl,
              ),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.brandBlue,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.brandGray,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  const _VersionFooter(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.mist,
            AppColors.background,
            AppColors.surface,
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.12,
            child: Image.asset(
              AppAssets.splashBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.brandBlue.withValues(alpha: 0.05),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              width: 260,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(180),
                ),
                color: AppColors.brandBlue.withValues(alpha: 0.04),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '1.0.0';
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: AppColors.brandGray.withValues(alpha: 0.35),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    'Version $version',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.brandGray,
                        ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: AppColors.brandGray.withValues(alpha: 0.35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppConstants.developedBy,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brandGray,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        );
      },
    );
  }
}
