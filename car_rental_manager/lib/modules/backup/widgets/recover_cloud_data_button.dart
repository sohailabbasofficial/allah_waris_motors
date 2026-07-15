import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/authorized_google_account.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';
import '../providers/backup_provider.dart';
import '../services/google_drive_service.dart';

/// One-tap button to pull the newest Google Drive backup into local SQLite.
///
/// Use after reinstall when the phone is empty but Drive still has data.
class RecoverCloudDataButton extends ConsumerStatefulWidget {
  const RecoverCloudDataButton({
    super.key,
    this.emphasized = false,
  });

  /// Larger banner style for empty dashboards.
  final bool emphasized;

  @override
  ConsumerState<RecoverCloudDataButton> createState() =>
      _RecoverCloudDataButtonState();
}

class _RecoverCloudDataButtonState
    extends ConsumerState<RecoverCloudDataButton> {
  bool _running = false;

  Future<void> _recover() async {
    if (_running) return;

    final backup = ref.read(backupProvider).valueOrNull;
    if (backup == null || !backup.isSignedIn) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Google Sign-In needed'),
          content: Text(
            'Sign in with ${AuthorizedGoogleAccount.email} to recover '
            'your cloud backup to this phone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign in'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
      final signedIn = await Navigator.of(context).pushNamed(
        AppRoutes.googleSignIn,
      );
      if (signedIn != true || !mounted) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recover cloud data?'),
        content: const Text(
          'This downloads your latest Google Drive backup and updates '
          'all local data on this phone (customers, ledger, payments).\n\n'
          'Local empty data will be replaced.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recover now'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _running = true);
    try {
      final count =
          await ref.read(backupProvider.notifier).restoreLatestFromCloud();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Recovered $count customers from Google Drive.'
                : 'Backup restored. If lists are still empty, check Drive Trash.',
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      if (e.isAccessDenied) {
        await Navigator.of(context).pushNamed(
          AppRoutes.googleSignIn,
          arguments: const {'asGate': true},
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _running || (ref.watch(backupProvider).valueOrNull?.isBusy ?? false);
    final scheme = Theme.of(context).colorScheme;

    if (widget.emphasized) {
      return PremiumCard(
        color: AppColors.cardAmber.withValues(alpha: 0.12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cardAmber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(AppIcons.restore, color: AppColors.cardAmber),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'App reinstalled? Recover your data from Google Drive',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'One tap downloads the latest cloud backup and updates local data on this phone.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: busy ? null : _recover,
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.restore),
              label: Text(busy ? 'Recovering…' : 'Recover Cloud Data'),
            ),
          ],
        ),
      );
    }

    return FilledButton.tonalIcon(
      onPressed: busy ? null : _recover,
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.restore),
      label: Text(busy ? 'Recovering…' : 'Recover Cloud Data'),
    );
  }
}
