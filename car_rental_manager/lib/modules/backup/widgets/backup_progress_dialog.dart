import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

class BackupProgressDialog extends StatelessWidget {
  const BackupProgressDialog({
    super.key,
    required this.message,
  });

  final String message;

  static Future<void> show(BuildContext context, {required String message}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackupProgressDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
