import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/backup_file_info.dart';
import '../utils/backup_formatters.dart';

class RestoreDialog {
  RestoreDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required BackupFileInfo file,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(AppIcons.warning, color: scheme.error, size: 36),
        title: const Text('Restore backup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will replace the current database with:',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              file.name,
              style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(BackupFormatters.formatDateTime(file.modifiedTime)),
            Text(file.sizeLabel),
            const SizedBox(height: AppSpacing.md),
            Text(
              'This cannot be undone. Continue?',
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
