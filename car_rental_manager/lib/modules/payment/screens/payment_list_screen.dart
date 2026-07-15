import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_states.dart';
import '../../../routes/app_routes.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_payment_widget.dart';
import '../widgets/payment_card.dart';

/// Global payment history list with search and date filter.
class PaymentListScreen extends ConsumerStatefulWidget {
  const PaymentListScreen({super.key});

  @override
  ConsumerState<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends ConsumerState<PaymentListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).pushNamed(AppRoutes.addPayment);
  }

  Future<void> _pickFilterDate() async {
    final current = ref.read(paymentListProvider).valueOrNull?.filterDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(paymentListProvider.notifier).setFilterDate(picked);
    }
  }

  Future<void> _delete(PaymentModel payment) async {
    final ok = await DeleteConfirmationDialog.show(
      context,
      title: 'Delete Payment',
      message:
          'Delete payment of ${payment.paymentAmount} for ${payment.customerName}? Remaining balance will be restored.',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(paymentListProvider.notifier).deletePayment(payment.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment deleted')),
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
    final asyncState = ref.watch(paymentListProvider);
    final filterDate = asyncState.valueOrNull?.filterDate;
    final isRefreshing = asyncState.isLoading && asyncState.hasValue;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
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
                  ref.read(paymentListProvider.notifier).setFilterDate(null),
              icon: const Icon(AppIcons.filter),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(paymentListProvider.notifier).refresh(),
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(AppIcons.add),
        label: const Text('Add Payment'),
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
                ref.read(paymentListProvider.notifier).setQuery(value);
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
                  onDeleted: () =>
                      ref.read(paymentListProvider.notifier).setFilterDate(null),
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
                    'Payments use SQLite (Android/iOS/desktop). Web shows an empty list.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const AppLoading(label: 'Loading payments…'),
              error: (e, _) => AppErrorState(
                title: 'Could not load payments',
                message: e.toString(),
                onRetry: () =>
                    ref.read(paymentListProvider.notifier).refresh(),
              ),
              data: (state) {
                final items = state.filtered;
                if (state.payments.isEmpty) {
                  return EmptyPaymentWidget(
                    actionLabel: 'Add Payment',
                    onAction: _openAdd,
                  );
                }
                if (items.isEmpty) {
                  return const EmptyPaymentWidget(
                    title: 'No matches',
                    message: 'Try another name or clear the date filter.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(paymentListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 4),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final payment = items[index];
                      return PaymentCard(
                        index: index,
                        payment: payment,
                        onEdit: () => Navigator.of(context).pushNamed(
                          AppRoutes.editPayment,
                          arguments: payment.id,
                        ),
                        onDelete: () => _delete(payment),
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
