import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/auth/authorized_google_account.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../modules/backup/providers/backup_provider.dart';
import '../../../modules/backup/utils/backup_formatters.dart';
import '../../../modules/backup/widgets/auto_backup_switch.dart';
import '../../../modules/backup/widgets/backup_status_card.dart';
import '../../../modules/backup/widgets/google_account_card.dart';
import '../../../modules/backup/widgets/recover_cloud_data_button.dart';
import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_providers.dart';
import '../../auth/providers/google_session_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/theme_provider.dart';

/// Modern settings: security, appearance, app info, and backup & restore.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmResetPin(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetPin),
        content: Text(l10n.resetPinConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reset),
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
    final l10n = context.l10n;
    showAboutDialog(
      context: context,
      applicationName: l10n.appName,
      applicationVersion: '1.0.0',
      applicationLegalese: l10n.tagline,
      children: [
        const SizedBox(height: 12),
        Text(l10n.aboutBody),
        const SizedBox(height: 12),
        const Text(
          AppConstants.developedBy,
          style: TextStyle(fontWeight: FontWeight.w600),
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

  Future<void> _logoutGoogle(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout Google account?'),
        content: const Text(
          'You will be signed out of Backup & Restore and must sign in again '
          'with the workshop owner Google account to use the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

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
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final language = AppLanguage.fromCode(locale.languageCode);
    final biometricEnabled = ref.watch(biometricEnabledProvider);
    final biometricAvailable = ref.watch(biometricAvailableProvider);
    final backupAsync = ref.watch(backupProvider);
    final backupState = backupAsync.valueOrNull;
    final googleAuthorized = backupState?.isSignedIn == true &&
        AuthorizedGoogleAccount.isAuthorized(backupState?.accountEmail);
    final showFingerprint = googleAuthorized &&
        biometricAvailable.maybeWhen(
          data: (v) => v,
          orElse: () => false,
        );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.md,
          AppSpacing.pagePadding,
          AppSpacing.xxxl,
        ),
        children: [
          SectionHeader(title: l10n.security),
          _SettingsCard(
            children: [
              ListTile(
                leading: const _LeadingIcon(icon: AppIcons.pin),
                title: Text(l10n.changePin),
                trailing: const Icon(AppIcons.chevron),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.changePin),
              ),
              if (!googleAuthorized)
                ListTile(
                  leading: const _LeadingIcon(icon: AppIcons.fingerprint),
                  title: Text(l10n.fingerprintLogin),
                  subtitle: const Text(
                    'Available after signing in with the owner Google account',
                  ),
                  enabled: false,
                ),
              if (showFingerprint)
                SwitchListTile(
                  secondary: const _LeadingIcon(icon: AppIcons.fingerprint),
                  title: Text(l10n.fingerprintLogin),
                  subtitle: Text(l10n.fingerprintSubtitle),
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
                leading: _LeadingIcon(
                  icon: AppIcons.security,
                  color: scheme.error,
                ),
                title: Text(l10n.resetPin),
                trailing: const Icon(AppIcons.chevron),
                onTap: () => _confirmResetPin(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.language),
          _SettingsCard(
            children: [
              _ThemeOptionTile(
                icon: Icons.language_rounded,
                title: l10n.languageEnglishNative,
                selected: language == AppLanguage.english,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLanguage(AppLanguage.english),
              ),
              _ThemeOptionTile(
                icon: Icons.translate_rounded,
                title: l10n.languageUrduNative,
                selected: language == AppLanguage.urdu,
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLanguage(AppLanguage.urdu),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.appearance),
          _SettingsCard(
            children: [
              _ThemeOptionTile(
                icon: Icons.light_mode_rounded,
                title: l10n.lightTheme,
                selected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              _ThemeOptionTile(
                icon: Icons.dark_mode_rounded,
                title: l10n.darkTheme,
                selected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
              _ThemeOptionTile(
                icon: AppIcons.theme,
                title: l10n.systemTheme,
                selected: themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.app),
          _SettingsCard(
            children: [
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '...';
                  final build = snapshot.data?.buildNumber ?? '';
                  return ListTile(
                    leading: const _LeadingIcon(icon: AppIcons.info),
                    title: Text(l10n.appVersion),
                    subtitle: Text(
                      build.isEmpty ? version : '$version ($build)',
                    ),
                  );
                },
              ),
              ListTile(
                leading: const _LeadingIcon(icon: AppIcons.notes),
                title: Text(l10n.aboutApp),
                trailing: const Icon(AppIcons.chevron),
                onTap: () => _showAbout(context),
              ),
              const ListTile(
                leading: _LeadingIcon(icon: AppIcons.customers),
                title: Text('Developer'),
                subtitle: Text(AppConstants.developedBy),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(title: l10n.backupAndRestore),
          const RecoverCloudDataButton(emphasized: true),
          const SizedBox(height: AppSpacing.sm),
          if (backupState != null) ...[
            GoogleAccountCard(
              state: backupState,
              onConnect: backupState.isBusy
                  ? null
                  : () =>
                      Navigator.of(context).pushNamed(AppRoutes.googleSignIn),
              onDisconnect: backupState.isBusy
                  ? null
                  : () => _logoutGoogle(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
            BackupStatusCard(state: backupState),
            const SizedBox(height: AppSpacing.sm),
            AutoBackupSwitch(
              enabled: backupState.autoBackupEnabled,
              timeLabel: backupState.autoBackupTimeLabel,
              enabledControls: !backupState.isBusy && backupState.isSignedIn,
              onEnabledChanged: (value) => ref
                  .read(backupProvider.notifier)
                  .setAutoBackupEnabled(value),
              onPickTime: () => _pickBackupTime(context, ref),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          _SettingsCard(
            children: [
              ListTile(
                leading: const _LeadingIcon(icon: AppIcons.backup),
                title: const Text('Backup Now'),
                subtitle: Text(
                  backupState == null
                      ? 'Open backup center'
                      : 'Last: ${BackupFormatters.formatDateTime(backupState.lastBackupAt)}',
                ),
                trailing: const Icon(AppIcons.chevron),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
              ),
              ListTile(
                leading: const _LeadingIcon(icon: AppIcons.restore),
                title: const Text('Restore Backup'),
                subtitle: const Text('Replace local database from Drive'),
                trailing: const Icon(AppIcons.chevron),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.restoreBackup),
              ),
              ListTile(
                leading: const _LeadingIcon(icon: AppIcons.settings),
                title: const Text('Backup Center'),
                subtitle: const Text('Full backup & restore options'),
                trailing: const Icon(AppIcons.chevron),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.backup),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, this.color});

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: accent, size: AppSpacing.iconSize),
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
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: _LeadingIcon(icon: icon),
      title: Text(title),
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: selected ? scheme.primary : scheme.outline,
      ),
      onTap: onTap,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
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
