import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
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
      BackupStatus.success => AppColors.received,
      BackupStatus.failed => AppColors.remaining,
      BackupStatus.skipped => scheme.tertiary,
      BackupStatus.inProgress => AppColors.customers,
      BackupStatus.idle => scheme.outline,
    };

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(AppIcons.backup, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Last backup',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _row(context, 'Date & time',
              BackupFormatters.formatDateTime(state.lastBackupAt)),
          _row(context, 'File size', state.lastBackupSizeLabel),
          _row(context, 'Status', status.label, valueColor: color),
          if (state.progressMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.progressMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
