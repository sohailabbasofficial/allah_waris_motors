import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../routes/app_routes.dart';
import '../providers/transaction_provider.dart';
import '../widgets/delete_dialog.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTx = ref.watch(transactionDetailProvider(transactionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
        actions: [
          asyncTx.maybeWhen(
            data: (tx) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
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
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  _delete(context, ref, '${tx.description} / ${tx.customerName}'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncTx.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tx) {
          final colorScheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TransactionInfoTile(
                        icon: Icons.person_outline,
                        label: 'Customer',
                        value: tx.customerName,
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Date',
                        value: DateFormat('dd MMM yyyy').format(tx.date),
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.category_outlined,
                        label: 'Description',
                        value: tx.description,
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.notes_outlined,
                        label: 'Notes',
                        value: (tx.notes == null || tx.notes!.trim().isEmpty)
                            ? '-'
                            : tx.notes!,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TransactionInfoTile(
                        icon: Icons.payments_outlined,
                        label: 'Total Amount',
                        value: CurrencyFormatter.format(tx.totalAmount),
                        valueColor: colorScheme.primary,
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.south_west_rounded,
                        label: 'Received Amount',
                        value: CurrencyFormatter.format(tx.receivedAmount),
                        valueColor: const Color(0xFF2E7D32),
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.trending_down,
                        label: 'Remaining Amount',
                        value: CurrencyFormatter.format(tx.remainingAmount),
                        valueColor: colorScheme.error,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TransactionInfoTile(
                        icon: Icons.schedule,
                        label: 'Created',
                        value: DateFormat('dd MMM yyyy, hh:mm a')
                            .format(tx.createdAt),
                      ),
                      const Divider(),
                      TransactionInfoTile(
                        icon: Icons.update,
                        label: 'Updated',
                        value: DateFormat('dd MMM yyyy, hh:mm a')
                            .format(tx.updatedAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.editTransaction,
                        arguments: transactionId,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      icon: const Icon(Icons.delete_outline),
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
