import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';
import '../providers/payment_provider.dart';
import '../widgets/empty_payment_widget.dart';
import '../widgets/payment_history_tile.dart';

/// Customer-scoped payment history.
class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.customerId,
    this.customerName,
  });

  final int customerId;
  final String? customerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(paymentListProvider);
    final title = customerName == null || customerName!.isEmpty
        ? 'Payment History'
        : 'Payments · $customerName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).pushNamed(
            AppRoutes.addPayment,
            arguments: customerId,
          );
        },
        icon: const Icon(AppIcons.add),
        label: const Text('Add Payment'),
      ),
      body: asyncState.when(
        loading: () => const AppLoading(label: 'Loading payments…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load payments',
          message: e.toString(),
          onRetry: () => ref.read(paymentListProvider.notifier).refresh(),
        ),
        data: (state) {
          final items = state.payments
              .where((p) => p.customerId == customerId)
              .toList();
          if (items.isEmpty) {
            return EmptyPaymentWidget(
              title: 'No payments for this customer',
              message: 'Record a payment to reduce their remaining balance.',
              actionLabel: 'Add Payment',
              onAction: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.addPayment,
                  arguments: customerId,
                );
              },
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(paymentListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                AppSpacing.sm,
                AppSpacing.pagePadding,
                100,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final payment = items[index];
                return PremiumCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.editPayment,
                    arguments: payment.id,
                  ),
                  child: Column(
                    children: [
                      PaymentHistoryTile(payment: payment),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remaining after: ${CurrencyFormatter.format(payment.remainingBalance)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.remaining,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
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
