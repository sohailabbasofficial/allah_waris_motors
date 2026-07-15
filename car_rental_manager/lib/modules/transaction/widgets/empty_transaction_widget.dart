import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_states.dart';

class EmptyTransactionWidget extends StatelessWidget {
  const EmptyTransactionWidget({
    super.key,
    this.title = 'No transactions yet',
    this.message = 'Tap Add Transaction to create the first record.',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: AppIcons.transactions,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
