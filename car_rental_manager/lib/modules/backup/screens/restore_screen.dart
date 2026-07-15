import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/authorized_google_account.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/app_routes.dart';
import '../models/backup_file_info.dart';
import '../providers/backup_provider.dart';
import '../services/google_drive_service.dart';
import '../widgets/backup_history_tile.dart';
import '../widgets/recover_cloud_data_button.dart';
import '../widgets/restore_dialog.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  BackupFileInfo? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _showAccessDenied() {
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

  Future<void> _load() async {
    try {
      await ref.read(backupProvider.notifier).loadRemoteBackups();
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      if (e.isAccessDenied) {
        await _showAccessDenied();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _restore() async {
    final file = _selected;
    if (file == null) return;
    final ok = await RestoreDialog.confirm(context, file: file);
    if (!ok || !mounted) return;

    try {
      await ref.read(backupProvider.notifier).restore(file);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Restore successful. Your customers and ledger are reloading…',
          ),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      if (e.isAccessDenied) {
        await _showAccessDenied();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backupAsync = ref.watch(backupProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restore Backup'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: backupAsync.valueOrNull?.isBusy == true ? null : _load,
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected == null || backupAsync.valueOrNull?.isBusy == true
            ? null
            : _restore,
        icon: const Icon(AppIcons.restore),
        label: const Text('Restore'),
      ),
      body: backupAsync.when(
        loading: () => const AppLoading(label: 'Loading backups…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load backups',
          message: e.toString(),
          onRetry: _load,
        ),
        data: (state) {
          if (kIsWeb) {
            return const AppEmptyState(
              icon: AppIcons.info,
              title: 'Not available on web',
              message: 'Restore is not available on web.',
            );
          }

          if (!state.isSignedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppEmptyState(
                      icon: AppIcons.backup,
                      title: 'Connect Google Drive',
                      message: 'Sign in to list available backup files.',
                      compact: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.googleSignIn),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Connect Google'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.isBusy && state.availableBackups.isEmpty) {
            return AppLoading(
              label: state.progressMessage ?? 'Loading backups…',
            );
          }

          if (state.availableBackups.isEmpty) {
            return const AppEmptyState(
              icon: AppIcons.backup,
              title: 'No backups found',
              message:
                  'No backup files found in Google Drive. Create a backup first.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              AppSpacing.pagePadding,
              96,
            ),
            children: [
              if (state.progressMessage != null && state.isBusy)
                PremiumCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(state.progressMessage!)),
                    ],
                  ),
                ),
              const RecoverCloudDataButton(emphasized: true),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Or pick a backup manually'),
              ...state.availableBackups.map(
                (file) => BackupHistoryTile(
                  file: file,
                  selected: _selected?.id == file.id,
                  onTap: state.isBusy
                      ? null
                      : () => setState(() => _selected = file),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
