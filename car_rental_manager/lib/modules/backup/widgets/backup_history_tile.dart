import 'package:flutter/material.dart';

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
    return Card(
      color: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined),
        title: Text(file.name),
        subtitle: Text(
          '${BackupFormatters.formatDateTime(file.modifiedTime)} · ${file.sizeLabel}',
        ),
        trailing: selected
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
