import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickFilterDate,
            icon: Icon(
              filterDate == null
                  ? Icons.calendar_today_outlined
                  : Icons.event_available,
            ),
          ),
          if (filterDate != null)
            IconButton(
              tooltip: 'Clear date filter',
              onPressed: () =>
                  ref.read(paymentListProvider.notifier).setFilterDate(null),
              icon: const Icon(Icons.filter_alt_off_outlined),
            ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(paymentListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Add Payment'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                ref.read(paymentListProvider.notifier).setQuery(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search by customer name',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(paymentListProvider.notifier).setQuery('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          if (filterDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.event, size: 18),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Payments use SQLite (Android/iOS/desktop). Web shows an empty list.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.toString()),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.read(paymentListProvider.notifier).refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
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
