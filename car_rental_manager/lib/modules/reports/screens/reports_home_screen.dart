import 'package:flutter/material.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = <_ReportNavItem>[
      _ReportNavItem(
        title: l10n.dailyReport,
        subtitle: l10n.dailyReportDesc,
        icon: AppIcons.today,
        color: AppColors.accent,
        route: AppRoutes.dailyReport,
      ),
      _ReportNavItem(
        title: l10n.monthlyReport,
        subtitle: l10n.monthlyReportDesc,
        icon: AppIcons.calendar,
        color: AppColors.secondary,
        route: AppRoutes.monthlyReport,
      ),
      _ReportNavItem(
        title: l10n.customerLedger,
        subtitle: l10n.customerLedgerDesc,
        icon: AppIcons.ledger,
        color: AppColors.primary,
        route: AppRoutes.customerLedger,
      ),
      _ReportNavItem(
        title: l10n.outstandingCustomers,
        subtitle: l10n.outstandingCustomersDesc,
        icon: AppIcons.warning,
        color: AppColors.warning,
        route: AppRoutes.outstandingCustomers,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.reports)),
      body: Builder(
        builder: (context) {
          final r = Responsive.of(context);
          final cols = r.reportsCrossAxisCount();
          return Responsive.constrain(
            context: context,
            child: GridView.builder(
              padding: EdgeInsets.all(r.pagePadding),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: cols == 2
                    ? 2.35
                    : (r.width < 360 ? 2.3 : 2.7),
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return PremiumCard(
                  onTap: () => Navigator.of(context).pushNamed(item.route),
                  child: Row(
                    children: [
                      Container(
                        width: r.width < 360 ? 44 : 52,
                        height: r.width < 360 ? 44 : 52,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: Colors.white),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(AppIcons.chevron),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReportNavItem {
  const _ReportNavItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;
}
