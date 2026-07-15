import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/quick_action_tile.dart';
import '../../../core/widgets/section_header.dart';
import '../../../modules/backup/widgets/recover_cloud_data_button.dart';
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
    final l10n = context.l10n;
    final dashboardAsync = ref.watch(dashboardProvider);
    final isRefreshing = dashboardAsync.isLoading && dashboardAsync.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: isRefreshing
                ? null
                : () => ref.read(dashboardProvider.notifier).refresh(),
            icon: const Icon(AppIcons.refresh),
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(AppIcons.settings),
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
        icon: const Icon(AppIcons.addCustomer),
        label: Text(l10n.addCustomer),
      ),
      body: dashboardAsync.when(
        loading: () => AppLoading(label: l10n.loading),
        error: (error, _) => AppErrorState(
          title: l10n.couldNotLoadDashboard,
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
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final crossAxisCount = r.statsCrossAxisCount();
    final bottomPad = 88.0 + MediaQuery.paddingOf(context).bottom;

    return Responsive.constrain(
      context: context,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              r.pagePadding,
              AppSpacing.lg,
              r.pagePadding,
              bottomPad,
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
                  const SizedBox(height: AppSpacing.md),
                  const _WebSqliteBanner(),
                ],
                if (state.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const RecoverCloudDataButton(emphasized: true),
                ],
                const SizedBox(height: AppSpacing.xl),
                SectionHeader(title: l10n.overview),
                const SizedBox(height: AppSpacing.sm),
                _StatsGrid(
                  state: state,
                  crossAxisCount: crossAxisCount,
                  mainAxisExtent: r.statsMainAxisExtent(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(title: l10n.quickActions),
                const SizedBox(height: AppSpacing.sm),
                const _QuickActionsGrid(),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: l10n.recentCustomers,
                  trailing: IconButton(
                    tooltip: l10n.seeAll,
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.customers),
                    icon: const Icon(AppIcons.customers, size: 20),
                  ),
                ),
                _RecentCustomersCard(
                  state: state,
                  onAddCustomer: onAddCustomer,
                ),
                const SizedBox(height: AppSpacing.xxl),
                SectionHeader(
                  title: l10n.recentActivity,
                  trailing: IconButton(
                    tooltip: l10n.seeAll,
                    onPressed: () => Navigator.of(context)
                        .pushNamed(AppRoutes.transactions),
                    icon: const Icon(AppIcons.calendar, size: 20),
                  ),
                ),
                _RecentTransactionsCard(state: state),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = Responsive.of(context);
    final columns = r.quickActionsCrossAxisCount();

    final actions = [
      (
        AppIcons.customers,
        l10n.customers,
        l10n.customersActionDesc,
        AppColors.cardBlue,
        AppRoutes.customers,
      ),
      (
        AppIcons.transactions,
        l10n.transactions,
        l10n.transactionsActionDesc,
        AppColors.cardAmber,
        AppRoutes.transactions,
      ),
      (
        AppIcons.payments,
        l10n.payments,
        l10n.paymentsActionDesc,
        AppColors.cardGreen,
        AppRoutes.payments,
      ),
      (
        AppIcons.reports,
        l10n.reports,
        l10n.reportsActionDesc,
        AppColors.cardPurple,
        AppRoutes.reports,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: r.quickActionsChildAspectRatio(),
      ),
      itemBuilder: (context, index) {
        final item = actions[index];
        return QuickActionTile(
          icon: item.$1,
          label: item.$2,
          description: item.$3,
          color: item.$4,
          onTap: () => Navigator.of(context).pushNamed(item.$5),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.state,
    required this.crossAxisCount,
    required this.mainAxisExtent,
  });

  final DashboardState state;
  final int crossAxisCount;
  final double mainAxisExtent;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stats = state.stats;
    final cards = <({
      String title,
      String value,
      String subtitle,
      String? footer,
      Color? footerColor,
      IconData icon,
      Color color,
    })>[
      (
        title: l10n.totalCustomers,
        value: '${stats.totalCustomers}',
        subtitle: l10n.registeredCustomers,
        footer: l10n.activeBook,
        footerColor: AppColors.cardGreen,
        icon: AppIcons.customers,
        color: AppColors.cardBlue,
      ),
      (
        title: l10n.totalUdhaar,
        value: CurrencyFormatter.format(stats.totalUdhaar),
        subtitle: l10n.outstandingCredit,
        footer: l10n.needsFollowUp,
        footerColor: AppColors.cardAmber,
        icon: AppIcons.money,
        color: AppColors.cardAmber,
      ),
      (
        title: l10n.totalReceived,
        value: CurrencyFormatter.format(stats.totalReceived),
        subtitle: l10n.paymentsCollected,
        footer: l10n.healthyInflow,
        footerColor: AppColors.cardGreen,
        icon: AppIcons.received,
        color: AppColors.cardGreen,
      ),
      (
        title: l10n.remainingBalance,
        value: CurrencyFormatter.format(stats.remainingBalance),
        subtitle: l10n.stillPending,
        footer: stats.remainingBalance > 0 ? l10n.actionNeeded : l10n.cleared,
        footerColor: stats.remainingBalance > 0
            ? AppColors.error
            : AppColors.cardGreen,
        icon: AppIcons.remaining,
        color: AppColors.error,
      ),
      (
        title: l10n.todaysCollection,
        value: CurrencyFormatter.format(stats.todaysCollection),
        subtitle: l10n.paymentsToday,
        footer: l10n.liveTotal,
        footerColor: AppColors.cardPurple,
        icon: AppIcons.today,
        color: AppColors.cardPurple,
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
        mainAxisExtent: mainAxisExtent,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return DashboardCard(
          index: index,
          title: card.title,
          value: card.value,
          subtitle: card.subtitle,
          footer: card.footer,
          footerColor: card.footerColor,
          icon: card.icon,
          color: card.color,
        );
      },
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
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: state.recentCustomers.isEmpty
          ? EmptyStateWidget(
              icon: AppIcons.customer,
              title: context.l10n.noCustomersYet,
              message: context.l10n.noCustomersHint,
              actionLabel: context.l10n.addCustomer,
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
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
    return PremiumCard(
      padding: EdgeInsets.zero,
      child: state.recentTransactions.isEmpty
          ? EmptyStateWidget(
              icon: AppIcons.transactions,
              title: context.l10n.noTransactionsYet,
              message: context.l10n.noTransactionsHint,
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
                    const Divider(height: 1, indent: 16, endIndent: 16),
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
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(
              AppIcons.info,
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
