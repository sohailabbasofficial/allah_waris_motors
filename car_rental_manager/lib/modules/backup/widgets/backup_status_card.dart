import 'package:flutter/material.dart';

import '../models/backup_state.dart';
import '../models/backup_status.dart';
import '../utils/backup_formatters.dart';

class BackupStatusCard extends StatelessWidget {
  const BackupStatusCard({super.key, required this.state});

  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = state.lastBackupStatus;
    final color = switch (status) {
      BackupStatus.success => scheme.primary,
      BackupStatus.failed => scheme.error,
      BackupStatus.skipped => scheme.tertiary,
      BackupStatus.inProgress => scheme.secondary,
      BackupStatus.idle => scheme.outline,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last backup',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _row('Date & time', BackupFormatters.formatDateTime(state.lastBackupAt)),
            _row('File size', state.lastBackupSizeLabel),
            _row(
              'Status',
              status.label,
              valueColor: color,
            ),
            if (state.progressMessage != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: 8),
              Text(state.progressMessage!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
