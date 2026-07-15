import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../routes/app_routes.dart';
import '../models/dashboard_state.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/recent_customer_tile.dart';
import '../widgets/recent_transaction_tile.dart';

/// Module 3 — responsive business dashboard.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);
    final isRefreshing = dashboardAsync.isLoading && dashboardAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            tooltip: 'Customers',
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.customers),
          ),
          IconButton(
            tooltip: 'Transactions',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.transactions),
          ),
          IconButton(
            tooltip: 'Payments',
            icon: const Icon(Icons.payments_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.payments),
          ),
          IconButton(
            tooltip: 'Reports',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.reports),
          ),
          IconButton(
            tooltip: 'Backup',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.backup),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(dashboardProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added =
              await Navigator.of(context).pushNamed(AppRoutes.addCustomer);
          if (added == true) {
            await ref.read(dashboardProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Customer'),
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorBody(
          message: error.toString(),
          onRetry: () => ref.read(dashboardProvider.notifier).refresh(),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
          child: _DashboardBody(
            state: state,
            isRefreshing: isRefreshing,
            onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
            onAddCustomer: () async {
              final added = await Navigator.of(context)
                  .pushNamed(AppRoutes.addCustomer);
              if (added == true) {
                await ref.read(dashboardProvider.notifier).refresh();
              }
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.state,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onAddCustomer,
  });

  final DashboardState state;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1100
            ? 5
            : width >= 750
                ? 3
                : width >= 520
                    ? 2
                    : 1;
        final cardAspect = crossAxisCount >= 3
            ? 1.35
            : crossAxisCount == 2
                ? 1.45
                : 2.4;
        final horizontalPadding = width >= 900 ? 32.0 : 16.0;

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DashboardHeader(
                    isRefreshing: isRefreshing,
                    onRefresh: () {
                      onRefresh();
                    },
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 12),
                    const _WebSqliteBanner(),
                  ],
                  const SizedBox(height: 20),
                  _StatsGrid(
                    state: state,
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: cardAspect,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(
                        child: _SectionTitle(title: 'Recent Customers'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.customers),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RecentCustomersCard(
                    state: state,
                    onAddCustomer: onAddCustomer,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: _SectionTitle(title: 'Recent Transactions'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.transactions),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _RecentTransactionsCard(state: state),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.state,
    required this.crossAxisCount,
    required this.childAspectRatio,
  });

  final DashboardState state;
  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final cards = [
      (
        'Total Customers',
        '${stats.totalCustomers}',
        Icons.people_alt_rounded,
        const Color(0xFF1565C0),
      ),
      (
        'Total Udhaar',
        CurrencyFormatter.format(stats.totalUdhaar),
        Icons.account_balance_wallet_rounded,
        const Color(0xFFE65100),
      ),
      (
        'Total Received',
        CurrencyFormatter.format(stats.totalReceived),
        Icons.check_circle_rounded,
        const Color(0xFF2E7D32),
      ),
      (
        'Remaining Balance',
        CurrencyFormatter.format(stats.remainingBalance),
        Icons.trending_down_rounded,
        const Color(0xFFC62828),
      ),
      (
        "Today's Collection",
        CurrencyFormatter.format(stats.todaysCollection),
        Icons.today_rounded,
        const Color(0xFF6A1B9A),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return DashboardCard(
          index: index,
          title: card.$1,
          value: card.$2,
          icon: card.$3,
          color: card.$4,
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _RecentCustomersCard extends StatelessWidget {
  const _RecentCustomersCard({
    required this.state,
    required this.onAddCustomer,
  });

  final DashboardState state;
  final Future<void> Function() onAddCustomer;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: state.recentCustomers.isEmpty
          ? EmptyStateWidget(
              icon: Icons.person_off_outlined,
              title: 'No customers yet',
              message: 'Add your first customer to see them here.',
              actionLabel: 'Add Customer',
              onAction: () {
                onAddCustomer();
              },
            )
          : Column(
              children: [
                for (var i = 0; i < state.recentCustomers.length; i++) ...[
                  RecentCustomerTile(
                    customer: state.recentCustomers[i],
                    onViewDetails: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.customerDetail,
                        arguments: state.recentCustomers[i].id,
                      );
                    },
                  ),
                  if (i < state.recentCustomers.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: state.recentTransactions.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'No transactions yet',
              message: 'Payments will show up here once recorded.',
            )
          : Column(
              children: [
                for (var i = 0; i < state.recentTransactions.length; i++) ...[
                  RecentTransactionTile(
                    transaction: state.recentTransactions[i],
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.transactionDetail,
                        arguments: state.recentTransactions[i].id,
                      );
                    },
                  ),
                  if (i < state.recentTransactions.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _WebSqliteBanner extends StatelessWidget {
  const _WebSqliteBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'SQLite runs on Android/iOS/desktop. Web shows empty dashboard stats.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Could not load dashboard',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
