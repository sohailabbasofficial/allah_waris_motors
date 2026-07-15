import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/app_states.dart';

class EmptyReportWidget extends StatelessWidget {
  const EmptyReportWidget({
    super.key,
    this.title = 'No report data available',
    this.message = 'Try a different date or filter.',
    this.icon = AppIcons.reports,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      compact: true,
    );
  }
}
