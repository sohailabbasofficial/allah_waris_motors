import 'package:flutter/material.dart';

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
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
