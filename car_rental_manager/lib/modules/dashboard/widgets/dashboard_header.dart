import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/utils/responsive.dart';

/// Portal-style welcome header for the dashboard.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.onRefresh,
    this.isRefreshing = false,
  });

  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final narrow = r.width < 380;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                fontSize: narrow ? 20 : null,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.dashboardSubtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: narrow ? 12.5 : null,
              ),
        ),
      ],
    );

    final refreshButton = OutlinedButton.icon(
      onPressed: isRefreshing ? null : onRefresh,
      icon: isRefreshing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(AppIcons.refresh, size: 18),
      label: Text(l10n.refresh),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: Color(0xFFE5E7EB)),
        backgroundColor: AppColors.card,
        padding: EdgeInsets.symmetric(
          horizontal: narrow ? 10 : 14,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: refreshButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        refreshButton,
      ],
    );
  }
}
