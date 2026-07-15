import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
import '../models/backup_file_info.dart';
import '../utils/backup_formatters.dart';

class BackupHistoryTile extends StatelessWidget {
  const BackupHistoryTile({
    super.key,
    required this.file,
    this.selected = false,
    this.onTap,
  });

  final BackupFileInfo file;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PremiumCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: EdgeInsets.zero,
      color: selected ? scheme.secondaryContainer : null,
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(AppIcons.backup, color: scheme.primary),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${BackupFormatters.formatDateTime(file.modifiedTime)} · ${file.sizeLabel}',
        ),
        trailing: selected
            ? Icon(AppIcons.received, color: scheme.primary)
            : Icon(AppIcons.chevron, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
