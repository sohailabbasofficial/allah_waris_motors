import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
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
            tooltip: 'Contact Sync',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.contactSync),
            icon: const Icon(AppIcons.contacts),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isRefreshing
                ? null
                : () => ref.read(customerListProvider.notifier).refresh(),
            icon: const Icon(AppIcons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdd,
        icon: const Icon(AppIcons.addCustomer),
        label: const Text('Add Customer'),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pagePadding,
              ),
              child: Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Customer data is stored in SQLite (Android/iOS/desktop). Web shows an empty list.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => const AppLoading(label: 'Loading customers…'),
              error: (error, _) => AppErrorState(
                title: 'Could not load customers',
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
                    padding: const EdgeInsets.only(
                      bottom: 100,
                      top: AppSpacing.xs,
                    ),
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
