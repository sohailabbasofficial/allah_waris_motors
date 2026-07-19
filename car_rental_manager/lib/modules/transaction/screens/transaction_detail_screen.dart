import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../routes/app_routes.dart';
import '../providers/transaction_provider.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/transaction_amount_history_section.dart';
import '../widgets/transaction_info_tile.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final int transactionId;

  Future<void> _delete(BuildContext context, WidgetRef ref, String label) async {
    final ok = await DeleteDialog.show(
      context,
      title: 'Delete Transaction',
      message: 'Delete "$label"? This cannot be undone.',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(transactionListProvider.notifier).delete(transactionId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openAddAmount(BuildContext context) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.addTransactionAmount,
      arguments: transactionId,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTx = ref.watch(transactionDetailProvider(transactionId));
    final historyAsync =
        ref.watch(transactionAmountHistoryProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          asyncTx.maybeWhen(
            data: (_) => IconButton(
              tooltip: 'Add Amount',
              icon: const Icon(AppIcons.add),
              onPressed: () => _openAddAmount(context),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncTx.maybeWhen(
            data: (_) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(AppIcons.edit),
              onPressed: () => Navigator.of(context).pushNamed(
                AppRoutes.editTransaction,
                arguments: transactionId,
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncTx.maybeWhen(
            data: (tx) => IconButton(
              tooltip: 'Delete',
              icon: const Icon(AppIcons.delete),
              onPressed: () =>
                  _delete(context, ref, '${tx.description} / ${tx.customerName}'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncTx.when(
        loading: () => const AppLoading(label: 'Loading details…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load transaction',
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(transactionDetailProvider(transactionId)),
        ),
        data: (tx) {
          final colorScheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              PremiumCard(
                child: Column(
                  children: [
                    TransactionInfoTile(
                      icon: AppIcons.customer,
                      label: 'Customer',
                      value: tx.customerName,
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.calendar,
                      label: 'Date',
                      value: DateFormat('dd MMM yyyy').format(tx.date),
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.transactions,
                      label: 'Description',
                      value: tx.description,
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.notes,
                      label: 'Notes',
                      value: (tx.notes == null || tx.notes!.trim().isEmpty)
                          ? '-'
                          : tx.notes!,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumCard(
                child: Column(
                  children: [
                    TransactionInfoTile(
                      icon: AppIcons.money,
                      label: 'Total Amount',
                      value: CurrencyFormatter.format(tx.totalAmount),
                      valueColor: AppColors.brandBlue,
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.received,
                      label: 'Received Amount',
                      value: CurrencyFormatter.format(tx.receivedAmount),
                      valueColor: AppColors.received,
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.remaining,
                      label: 'Remaining Amount',
                      value: CurrencyFormatter.format(tx.remainingAmount),
                      valueColor: AppColors.remaining,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Could not load amount history: $e'),
                data: (additions) => TransactionAmountHistorySection(
                  transaction: tx,
                  additions: additions,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              PremiumCard(
                child: Column(
                  children: [
                    TransactionInfoTile(
                      icon: AppIcons.today,
                      label: 'Created',
                      value: DateFormat('dd MMM yyyy, hh:mm a')
                          .format(tx.createdAt),
                    ),
                    const Divider(height: 20),
                    TransactionInfoTile(
                      icon: AppIcons.refresh,
                      label: 'Updated',
                      value: DateFormat('dd MMM yyyy, hh:mm a')
                          .format(tx.updatedAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _openAddAmount(context),
                  icon: const Icon(AppIcons.add),
                  label: const Text('Add Amount'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.editTransaction,
                        arguments: transactionId,
                      ),
                      icon: const Icon(AppIcons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      onPressed: () => _delete(
                        context,
                        ref,
                        '${tx.description} / ${tx.customerName}',
                      ),
                      icon: const Icon(AppIcons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
