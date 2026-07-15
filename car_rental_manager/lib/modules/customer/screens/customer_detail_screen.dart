import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../routes/app_routes.dart';
import '../providers/customer_provider.dart';
import '../utils/customer_formatters.dart';
import '../widgets/customer_info_tile.dart';
import '../widgets/delete_confirmation_dialog.dart';

/// Full customer profile with edit/delete actions.
class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  Future<void> _edit(BuildContext context) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.editCustomer,
      arguments: customerId,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final confirmed = await DeleteConfirmationDialog.show(
      context,
      customerName: name,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(customerListProvider.notifier).deleteCustomer(customerId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer deleted')),
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
    final asyncCustomer = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          asyncCustomer.maybeWhen(
            data: (customer) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncCustomer.maybeWhen(
            data: (customer) => IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, customer.name),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncCustomer.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (customer) {
          final colorScheme = Theme.of(context).colorScheme;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text(
                          customer.name.isNotEmpty
                              ? customer.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        customer.name,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
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
                      CustomerInfoTile(
                        icon: Icons.badge_outlined,
                        label: 'CNIC',
                        value: CustomerFormatters.displayOrDash(customer.cnic),
                      ),
                      const Divider(),
                      CustomerInfoTile(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value:
                            CustomerFormatters.displayOrDash(customer.address),
                      ),
                      const Divider(),
                      CustomerInfoTile(
                        icon: Icons.calendar_month_outlined,
                        label: 'Created Date',
                        value: CustomerFormatters.formatDate(customer.createdAt),
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
                      CustomerInfoTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'Total Udhaar',
                        value: CurrencyFormatter.format(customer.totalUdhaar),
                        valueColor: const Color(0xFFE65100),
                      ),
                      const Divider(),
                      CustomerInfoTile(
                        icon: Icons.check_circle_outline,
                        label: 'Total Received',
                        value:
                            CurrencyFormatter.format(customer.totalReceived),
                        valueColor: const Color(0xFF2E7D32),
                      ),
                      const Divider(),
                      CustomerInfoTile(
                        icon: Icons.trending_down,
                        label: 'Remaining Balance',
                        value: CurrencyFormatter.format(
                          customer.remainingBalance,
                        ),
                        valueColor: colorScheme.error,
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
                        AppRoutes.customerLedger,
                        arguments: customer.id,
                      ),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: const Text('Ledger'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.paymentHistory,
                        arguments: {
                          'customerId': customer.id,
                          'customerName': customer.name,
                        },
                      ),
                      icon: const Icon(Icons.history),
                      label: const Text('Payments'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.addPayment,
                        arguments: customer.id,
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Add Payment'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(context),
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
                      onPressed: () => _delete(context, ref, customer.name),
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
