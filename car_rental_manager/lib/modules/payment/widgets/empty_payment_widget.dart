import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_states.dart';

class EmptyPaymentWidget extends StatelessWidget {
  const EmptyPaymentWidget({
    super.key,
    this.title = 'No payments yet',
    this.message = 'Tap Add Payment to record the first payment.',
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
      icon: AppIcons.payments,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
