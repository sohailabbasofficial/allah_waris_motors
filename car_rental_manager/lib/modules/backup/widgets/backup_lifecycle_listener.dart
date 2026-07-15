import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/backup_provider.dart';

/// Triggers automatic daily backup checks when the app resumes,
/// and Drive sync shortly after local data changes.
class BackupLifecycleListener extends ConsumerStatefulWidget {
  const BackupLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<BackupLifecycleListener> createState() =>
      _BackupLifecycleListenerState();
}

class _BackupLifecycleListenerState
    extends ConsumerState<BackupLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(backupProvider.notifier).maybeRunAutomaticBackup();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(dataChangeBusProvider, (previous, next) {
      if (previous == next) return;
      ref.read(backupProvider.notifier).scheduleSyncAfterLocalChange();
    });
    return widget.child;
  }
}
