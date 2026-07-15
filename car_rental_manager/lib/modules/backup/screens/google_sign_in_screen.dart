import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/authorized_google_account.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/auth/providers/google_session_provider.dart';
import '../../../routes/app_routes.dart';
import '../providers/backup_provider.dart';
import '../services/google_drive_service.dart';

/// Google Sign-In for app access + Drive backup (owner account only).
class GoogleSignInScreen extends ConsumerWidget {
  const GoogleSignInScreen({super.key});

  bool _asGate(Object? args) {
    if (args is Map && args['asGate'] == true) return true;
    return false;
  }

  Future<void> _showAccessDenied(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Denied'),
        content: Text(AuthorizedGoogleAccount.accessDeniedMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _onSignIn(
    BuildContext context,
    WidgetRef ref, {
    required bool asGate,
  }) async {
    try {
      await ref.read(backupProvider.notifier).connectGoogle();
      ref.invalidate(authorizedGoogleSessionProvider);
      if (!context.mounted) return;

      if (asGate) {
        final hasPin = ref.read(hasPinProvider);
        Navigator.of(context).pushNamedAndRemoveUntil(
          hasPin ? AppRoutes.login : AppRoutes.createPin,
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Drive connected')),
        );
        Navigator.of(context).pop(true);
      }
    } on GoogleAuthException catch (e) {
      if (!context.mounted) return;
      if (e.isAccessDenied) {
        await _showAccessDenied(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final message = '$e';
      if (message.contains(AuthorizedGoogleAccount.accessDeniedMessage) ||
          message.contains('Access Denied')) {
        await _showAccessDenied(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asGate = _asGate(ModalRoute.of(context)?.settings.arguments);
    final backupAsync = ref.watch(backupProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(asGate ? 'Owner Sign-In' : 'Connect Google Drive'),
        automaticallyImplyLeading: !asGate,
      ),
      body: backupAsync.when(
        loading: () => const AppLoading(label: 'Preparing…'),
        error: (e, _) => AppErrorState(
          title: 'Something went wrong',
          message: e.toString(),
          onRetry: () => ref.read(backupProvider.notifier).refresh(),
        ),
        data: (state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.pagePaddingWide),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 1),
                PremiumCard(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.backup,
                          size: 44,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        asGate
                            ? 'Sign in with the workshop owner Google account to unlock Allah Waris Motors.'
                            : 'Sign in with Google to upload and restore your SQLite backup.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Authorized account: ${AuthorizedGoogleAccount.email}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        asGate
                            ? 'Other Google accounts are blocked. After the first successful sign-in you can enable Fingerprint / Face Unlock.'
                            : 'A folder named "Car Rental Manager Backups" will be created in Drive. Only the owner account can sync.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                FilledButton.icon(
                  onPressed: state.isBusy
                      ? null
                      : () => _onSignIn(context, ref, asGate: asGate),
                  icon: state.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(
                    state.isBusy ? 'Connecting…' : 'Sign in with Google',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
