import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
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
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Payment'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 100),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final payment = items[index];
                return Card(
                  child: Column(
                    children: [
                      PaymentHistoryTile(
                        payment: payment,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.editPayment,
                          arguments: payment.id,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Remaining after: ${CurrencyFormatter.format(payment.remainingBalance)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w600,
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
