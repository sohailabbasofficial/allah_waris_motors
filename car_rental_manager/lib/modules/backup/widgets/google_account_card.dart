import 'package:flutter/material.dart';

import '../models/backup_state.dart';

class GoogleAccountCard extends StatelessWidget {
  const GoogleAccountCard({
    super.key,
    required this.state,
    required this.onConnect,
    required this.onDisconnect,
  });

  final BackupState state;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    final signedIn = state.isSignedIn &&
        (state.accountEmail?.isNotEmpty ?? false);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(signedIn ? Icons.cloud_done_outlined : Icons.cloud_off),
        ),
        title: Text(
          signedIn
              ? (state.accountDisplayName?.isNotEmpty == true
                  ? state.accountDisplayName!
                  : 'Google Drive connected')
              : 'Google Drive not connected',
        ),
        subtitle: Text(
          signedIn
              ? (state.accountEmail ?? '')
              : 'Sign in to back up your database',
        ),
        trailing: signedIn
            ? TextButton(
                onPressed: onDisconnect,
                child: const Text('Disconnect'),
              )
            : FilledButton(
                onPressed: onConnect,
                child: const Text('Connect'),
              ),
      ),
    );
  }
}
