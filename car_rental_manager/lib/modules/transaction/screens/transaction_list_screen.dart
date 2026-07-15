import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_states.dart';
import '../../../routes/app_routes.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/delete_dialog.dart';
import '../widgets/empty_transaction_widget.dart';
import '../widgets/transaction_card.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).pushNamed(AppRoutes.addTransaction);
  }

  Future<void> _pickFilterDate() async {
    final current = ref.read(transactionListProvider).valueOrNull?.filterDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(transactionListProvider.notifier).setFilterDate(picked);
    }
  }

  Future<void> _delete(TransactionModel tx) async {
    final ok = await DeleteDialog.show(
      context,
      title: 'Delete Transaction',
      message:
          'Delete ${tx.description} for ${tx.customerName}? This cannot be undone.',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(transactionListProvider.notifier).delete(tx.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(transactionListProvider);
    final filterDate = asyncState.valueOrNull?.filterDate;
    final isRefreshing = asyncState.isLoading && asyncState.hasValue;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickFilterDate,
            icon: Icon(
              filterDate == null ? AppIcons.calendar : AppIcons.today,
            ),
          ),
          if (filterDate != null)
            IconButton(
              tooltip: 'Clear date filter',
              onPressed: () =>
                  ref.read(transactionListProvider.notifier).setFilterDate(null),
              icon: const Icon(AppIcons.filter),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(transactionListProvider.notifier).refresh(),
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(AppIcons.add),
        label: const Text('Add Transaction'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.md,
              AppSpacing.pagePadding,
              AppSpacing.sm,
            ),
            child: AppSearchField(
              controller: _searchController,
              hintText: 'Search by customer name',
              onChanged: (value) {
                ref.read(transactionListProvider.notifier).setQuery(value);
                setState(() {});
              },
            ),
          ),
          if (filterDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(AppIcons.calendar, size: 18),
                  label: Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(filterDate)}',
                  ),
                  onDeleted: () => ref
                      .read(transactionListProvider.notifier)
                      .setFilterDate(null),
                ),
              ),
            ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
                vertical: 4,
              ),
              child: Material(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Transactions use SQLite (Android/iOS/desktop). Web shows an empty list.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const AppLoading(label: 'Loading transactions…'),
              error: (e, _) => AppErrorState(
                title: 'Could not load transactions',
                message: e.toString(),
                onRetry: () =>
                    ref.read(transactionListProvider.notifier).refresh(),
              ),
              data: (state) {
                final items = state.filtered;
                if (state.transactions.isEmpty) {
                  return EmptyTransactionWidget(
                    actionLabel: 'Add Transaction',
                    onAction: _openAdd,
                  );
                }
                if (items.isEmpty) {
                  return const EmptyTransactionWidget(
                    title: 'No matches',
                    message:
                        'Try another customer name or clear the date filter.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(transactionListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 4),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final tx = items[index];
                      return TransactionCard(
                        index: index,
                        transaction: tx,
                        onView: () => Navigator.of(context).pushNamed(
                          AppRoutes.transactionDetail,
                          arguments: tx.id,
                        ),
                        onEdit: () => Navigator.of(context).pushNamed(
                          AppRoutes.editTransaction,
                          arguments: tx.id,
                        ),
                        onDelete: () => _delete(tx),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
