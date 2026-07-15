import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';

class ReportsHomeScreen extends StatelessWidget {
  const ReportsHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = <_ReportNavItem>[
      _ReportNavItem(
        title: 'Daily Report',
        subtitle: 'Transactions and collections for a day',
        icon: Icons.today_outlined,
        route: AppRoutes.dailyReport,
      ),
      _ReportNavItem(
        title: 'Monthly Report',
        subtitle: 'Revenue and activity for a month',
        icon: Icons.calendar_month_outlined,
        route: AppRoutes.monthlyReport,
      ),
      _ReportNavItem(
        title: 'Customer Ledger',
        subtitle: 'Full transaction and payment history',
        icon: Icons.menu_book_outlined,
        route: AppRoutes.customerLedger,
      ),
      _ReportNavItem(
        title: 'Outstanding Customers',
        subtitle: 'Customers with remaining balance',
        icon: Icons.warning_amber_outlined,
        route: AppRoutes.outstandingCustomers,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: wide ? 2 : 1,
              mainAxisExtent: 120,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).pushNamed(item.route),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          child: Icon(item.icon, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
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
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
