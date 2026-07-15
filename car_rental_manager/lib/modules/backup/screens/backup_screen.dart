import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_routes.dart';
import '../providers/backup_provider.dart';
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

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(backupProvider.notifier).backupNow();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup uploaded to Google Drive')),
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
            icon: const Icon(Icons.restore_outlined),
          ),
        ],
      ),
      body: backupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$e'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.read(backupProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (kIsWeb)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text(
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
                onDisconnect: state.isBusy
                    ? null
                    : () async {
                        try {
                          await ref
                              .read(backupProvider.notifier)
                              .disconnectGoogle();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Google account disconnected'),
                            ),
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')),
                          );
                        }
                      },
              ),
              const SizedBox(height: 12),
              BackupStatusCard(state: state),
              const SizedBox(height: 12),
              AutoBackupSwitch(
                enabled: state.autoBackupEnabled,
                timeLabel: state.autoBackupTimeLabel,
                enabledControls: !state.isBusy && state.isSignedIn,
                onEnabledChanged: (value) => ref
                    .read(backupProvider.notifier)
                    .setAutoBackupEnabled(value),
                onPickTime: () => _pickTime(context, ref),
              ),
              const SizedBox(height: 20),
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
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(state.isBusy ? 'Working…' : 'Backup Now'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isBusy
                    ? null
                    : () => Navigator.of(context)
                        .pushNamed(AppRoutes.restoreBackup),
                icon: const Icon(Icons.cloud_download_outlined),
                label: const Text('Restore Backup'),
              ),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
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
