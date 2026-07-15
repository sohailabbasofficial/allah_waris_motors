import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_routes.dart';
import '../models/backup_file_info.dart';
import '../providers/backup_provider.dart';
import '../widgets/backup_history_tile.dart';
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

  Future<void> _load() async {
    try {
      await ref.read(backupProvider.notifier).loadRemoteBackups();
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
          content: Text('Restore successful. Reloading application data…'),
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.home,
        (route) => false,
      );
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
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selected == null || backupAsync.valueOrNull?.isBusy == true
            ? null
            : _restore,
        icon: const Icon(Icons.restore),
        label: const Text('Restore'),
      ),
      body: backupAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) {
          if (kIsWeb) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Restore is not available on web.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!state.isSignedIn) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Connect Google Drive to list backups.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(AppRoutes.googleSignIn),
                      child: const Text('Connect Google'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.isBusy && state.availableBackups.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(state.progressMessage ?? 'Loading backups…'),
                ],
              ),
            );
          }

          if (state.availableBackups.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No backup files found in Google Drive.\nCreate a backup first.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (state.progressMessage != null && state.isBusy)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: const CircularProgressIndicator(),
                      title: Text(state.progressMessage!),
                    ),
                  ),
                ),
              Text(
                'Select a backup to restore',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
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
