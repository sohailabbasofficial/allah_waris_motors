import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

/// Confirms destructive customer deletion.
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.customerName,
  });

  final String customerName;

  static Future<bool> show(
    BuildContext context, {
    required String customerName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteConfirmationDialog(customerName: customerName),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(AppIcons.delete, color: colorScheme.error, size: 28),
      ),
      title: const Text('Delete Customer'),
      content: Text(
        'Delete "$customerName"? This cannot be undone and related payments will also be removed.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(AppIcons.delete, size: 18),
          label: const Text('Delete'),
        ),
      ],
    );
  }
}
