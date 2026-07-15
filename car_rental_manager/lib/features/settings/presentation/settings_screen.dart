import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../modules/backup/providers/backup_provider.dart';
import '../../../modules/backup/utils/backup_formatters.dart';
import '../../../modules/backup/widgets/auto_backup_switch.dart';
import '../../../modules/backup/widgets/backup_status_card.dart';
import '../../../modules/backup/widgets/google_account_card.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/theme_provider.dart';

/// Modern settings: security, appearance, app info, and backup & restore.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmResetPin(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset PIN'),
        content: const Text(
          'This removes your current PIN. You will need to create a new one. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(pinServiceProvider).resetPin();
    await ref.read(biometricEnabledProvider.notifier).setEnabled(false);
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.createPin,
      (route) => false,
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: 'Local car rental management app.',
      children: const [
        SizedBox(height: 12),
        Text(
          'Allah Waris Motors helps you manage vehicles and rentals securely on this device.',
        ),
      ],
    );
  }

  Future<void> _pickBackupTime(BuildContext context, WidgetRef ref) async {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final backupAsync = ref.watch(backupProvider);
    final backupState = backupAsync.valueOrNull;
    final showFingerprint = biometricAvailable.maybeWhen(
      data: (v) => v,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _SectionHeader(title: 'Security'),
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.pin_outlined),
                title: const Text('Change PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.changePin),
              ),
              if (showFingerprint)
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Fingerprint Login'),
                  subtitle: const Text('Unlock with biometrics'),
                  value: biometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final ok = await ref
                          .read(biometricServiceProvider)
                          .authenticate(
                            reason:
                                'Confirm fingerprint to enable biometric login',
                          );
                      if (!ok) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fingerprint verification failed',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }
                    await ref
                        .read(biometricEnabledProvider.notifier)
                        .setEnabled(value);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.lock_reset,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: const Text('Reset PIN'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmResetPin(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Appearance'),
          _SettingsCard(
            children: [
              _ThemeOptionTile(
                icon: Icons.light_mode_outlined,
                title: 'Light Theme',
                selected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              _ThemeOptionTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Theme',
                selected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
              _ThemeOptionTile(
                icon: Icons.settings_brightness_outlined,
                title: 'System Theme',
                selected: themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'App'),
          _SettingsCard(
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  final build = snapshot.data?.buildNumber ?? '';
                  return ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('App Version'),
                    subtitle: Text(
                      build.isEmpty ? version : '$version ($build)',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.article_outlined),
                title: const Text('About App'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Backup & Restore'),
          if (backupState != null) ...[
            GoogleAccountCard(
              state: backupState,
              onConnect: backupState.isBusy
                  ? null
                  : () =>
                      Navigator.of(context).pushNamed(AppRoutes.googleSignIn),
              onDisconnect: backupState.isBusy
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(backupProvider.notifier)
                            .disconnectGoogle();
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    },
            ),
            const SizedBox(height: 8),
            BackupStatusCard(state: backupState),
            const SizedBox(height: 8),
            AutoBackupSwitch(
              enabled: backupState.autoBackupEnabled,
              timeLabel: backupState.autoBackupTimeLabel,
              enabledControls: !backupState.isBusy && backupState.isSignedIn,
              onEnabledChanged: (value) => ref
                  .read(backupProvider.notifier)
                  .setAutoBackupEnabled(value),
              onPickTime: () => _pickBackupTime(context, ref),
            ),
            const SizedBox(height: 8),
          ],
          _SettingsCard(
            children: [
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Backup Now'),
                subtitle: Text(
                  backupState == null
                      ? 'Open backup center'
                      : 'Last: ${BackupFormatters.formatDateTime(backupState.lastBackupAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Restore Backup'),
                subtitle: const Text('Replace local database from Drive'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.restoreBackup),
              ),
              ListTile(
                leading: const Icon(Icons.settings_backup_restore_outlined),
                title: const Text('Backup Center'),
                subtitle: const Text('Full backup & restore options'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: selected
          ? Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
            )
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}