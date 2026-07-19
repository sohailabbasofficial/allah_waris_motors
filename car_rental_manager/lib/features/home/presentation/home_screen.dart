import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/quick_action_tile.dart';
import '../../../modules/backup/widgets/recover_cloud_data_button.dart';
import '../../../modules/customer/screens/customer_list_screen.dart';
import '../../../modules/dashboard/screens/dashboard_screen.dart';
import '../../../modules/payment/screens/payment_list_screen.dart';
import '../../../modules/transaction/screens/transaction_list_screen.dart';
import '../../../routes/app_routes.dart';

/// Post-auth shell with Material 3 NavigationBar.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  void _openMore() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final sheetL10n = ctx.l10n;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sheetL10n.more,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                    QuickActionTile(
                      icon: AppIcons.reports,
                      label: sheetL10n.reports,
                      description: sheetL10n.reportsActionDesc,
                      color: AppColors.cardBlue,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(AppRoutes.reports);
                      },
                    ),
                    QuickActionTile(
                      icon: AppIcons.backup,
                      label: sheetL10n.backup,
                      description: sheetL10n.backupActionDesc,
                      color: AppColors.cardAmber,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(AppRoutes.backup);
                      },
                    ),
                    QuickActionTile(
                      icon: AppIcons.restore,
                      label: 'Recover Data',
                      description: 'Cloud → this phone',
                      color: AppColors.cardGreen,
                      onTap: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          builder: (sheetCtx) => const SafeArea(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(20, 8, 20, 24),
                              child: RecoverCloudDataButton(emphasized: true),
                            ),
                          ),
                        );
                      },
                    ),
                    QuickActionTile(
                      icon: AppIcons.contacts,
                      label: 'Contact Sync',
                      description: 'Find customers on phone',
                      color: AppColors.cardBlue,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(AppRoutes.contactSync);
                      },
                    ),
                    QuickActionTile(
                      icon: AppIcons.settings,
                      label: sheetL10n.settings,
                      description: sheetL10n.settingsActionDesc,
                      color: AppColors.cardPurple,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).pushNamed(AppRoutes.settings);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          CustomerListScreen(),
          TransactionListScreen(),
          PaymentListScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          if (value == 4) {
            _openMore();
            return;
          }
          setState(() => _index = value);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(AppIcons.dashboard),
            selectedIcon: const Icon(AppIcons.dashboard),
            label: l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.customers),
            label: l10n.customers,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.transactions),
            label: l10n.ledger,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.payments),
            label: l10n.payments,
          ),
          NavigationDestination(
            icon: const Icon(AppIcons.more),
            label: l10n.more,
          ),
        ],
      ),
    );
  }
}
