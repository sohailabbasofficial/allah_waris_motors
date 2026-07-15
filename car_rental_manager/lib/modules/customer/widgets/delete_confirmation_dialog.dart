import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Delete Customer'),
      content: Text(
        'Delete "$customerName"? This cannot be undone and related payments will also be removed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
