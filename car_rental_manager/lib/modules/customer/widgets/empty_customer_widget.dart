import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_states.dart';

/// Empty-state placeholder for the customer list.
class EmptyCustomerWidget extends StatelessWidget {
  const EmptyCustomerWidget({
    super.key,
    this.title = 'No customers yet',
    this.message = 'Tap Add Customer to create your first record.',
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
      icon: AppIcons.customers,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
