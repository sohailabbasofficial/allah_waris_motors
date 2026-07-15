import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../routes/app_routes.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_card.dart';
import '../widgets/delete_confirmation_dialog.dart';
import '../widgets/empty_customer_widget.dart';
import '../widgets/search_bar_widget.dart';

/// Lists all customers with search, edit, delete, and pull-to-refresh.
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAdd() async {
    await Navigator.of(context).pushNamed(AppRoutes.addCustomer);
  }

  Future<void> _openEdit(CustomerModel customer) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.editCustomer,
      arguments: customer.id,
    );
  }

  Future<void> _deleteCustomer(CustomerModel customer) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      customerName: customer.name,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref
          .read(customerListProvider.notifier)
          .deleteCustomer(customer.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted')),
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
    final asyncState = ref.watch(customerListProvider);
    final isRefreshing = asyncState.isLoading && asyncState.hasValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(customerListProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBarWidget(
              controller: _searchController,
              onChanged: (value) {
                ref.read(customerListProvider.notifier).setQuery(value);
                setState(() {});
              },
            ),
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Customer data is stored in SQLite (Android/iOS/desktop). Web shows an empty list.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorView(
                message: error.toString(),
                onRetry: () =>
                    ref.read(customerListProvider.notifier).refresh(),
              ),
              data: (state) {
                final items = state.filtered;
                if (state.customers.isEmpty) {
                  return EmptyCustomerWidget(
                    actionLabel: 'Add Customer',
                    onAction: _openAdd,
                  );
                }
                if (items.isEmpty) {
                  return const EmptyCustomerWidget(
                    title: 'No matches',
                    message: 'Try a different name or phone number.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customerListProvider.notifier).refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100, top: 4),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final customer = items[index];
                      return CustomerCard(
                        index: index,
                        customer: customer,
                        onEdit: () => _openEdit(customer),
                        onDelete: () => _deleteCustomer(customer),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.customerDetail,
                            arguments: customer.id,
                          );
                        },
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
