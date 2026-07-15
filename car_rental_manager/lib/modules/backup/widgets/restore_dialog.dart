import 'package:flutter/material.dart';

import '../models/backup_file_info.dart';
import '../utils/backup_formatters.dart';

class RestoreDialog {
  RestoreDialog._();

  static Future<bool> confirm(
    BuildContext context, {
    required BackupFileInfo file,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'This will replace the current database with:\n\n'
          '${file.name}\n'
          '${BackupFormatters.formatDateTime(file.modifiedTime)}\n'
          '${file.sizeLabel}\n\n'
          'This cannot be undone. Continue?',
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
