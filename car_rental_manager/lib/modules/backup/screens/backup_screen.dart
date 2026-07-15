import 'package:flutter/foundation.dart';
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
import '../widgets/auto_backup_switch.dart';
import '../widgets/backup_status_card.dart';
import '../widgets/google_account_card.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final state = ref.read(backupProvider).valueOrNull;
    if (state == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: state.autoBackupHour,
        minute: state.autoBackupMinute,
      ),
    );
    if (picked == null) return;
    await ref
        .read(backupProvider.notifier)
        .setAutoBackupTime(picked.hour, picked.minute);
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

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupProvider.notifier).backupNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup uploaded to Google Drive')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupProvider.notifier).disconnectGoogle();
      await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
      ref.invalidate(authorizedGoogleSessionProvider);
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.googleSignIn,
        (route) => false,
        arguments: const {'asGate': true},
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupAsync = ref.watch(backupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        actions: [
          IconButton(
            tooltip: 'Restore',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.restoreBackup),
            icon: const Icon(AppIcons.restore),
          ),
        ],
      ),
      body: backupAsync.when(
        loading: () => const AppLoading(label: 'Loading backup status…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load backup',
          message: e.toString(),
          onRetry: () => ref.read(backupProvider.notifier).refresh(),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.pagePadding),
            children: [
              if (kIsWeb)
                PremiumCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      AppIcons.info,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text(
                      'Backup requires Android, iOS, or desktop with Google Sign-In configured.',
                    ),
                  ),
                ),
              GoogleAccountCard(
                state: state,
                onConnect: state.isBusy
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(AppRoutes.googleSignIn),
                onDisconnect:
                    state.isBusy ? null : () => _logout(context, ref),
              ),
              const SizedBox(height: AppSpacing.md),
              BackupStatusCard(state: state),
              const SizedBox(height: AppSpacing.md),
              AutoBackupSwitch(
                enabled: state.autoBackupEnabled,
                timeLabel: state.autoBackupTimeLabel,
                enabledControls: !state.isBusy && state.isSignedIn,
                onEnabledChanged: (value) => ref
                    .read(backupProvider.notifier)
                    .setAutoBackupEnabled(value),
                onPickTime: () => _pickTime(context, ref),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: state.isBusy || !state.isSignedIn || kIsWeb
                    ? null
                    : () => _backup(context, ref),
                icon: state.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(AppIcons.backup),
                label: Text(state.isBusy ? 'Working…' : 'Backup Now'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(AppRoutes.restoreBackup),
                icon: const Icon(AppIcons.restore),
                label: const Text('Restore Backup'),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.lg),
                PremiumCard(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.45),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          state.errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Backups are stored in Google Drive under '
                '"Car Rental Manager Backup". Previous database backups are replaced.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
