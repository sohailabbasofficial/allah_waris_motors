import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteDialog(title: title, message: message),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      icon: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(AppIcons.delete, color: scheme.error),
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(AppIcons.delete, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
