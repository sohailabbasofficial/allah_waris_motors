import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/app_states.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/section_header.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          asyncCustomer.maybeWhen(
            data: (customer) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(AppIcons.edit),
              onPressed: () => _edit(context),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          asyncCustomer.maybeWhen(
            data: (customer) => IconButton(
              tooltip: 'Delete',
              icon: const Icon(AppIcons.delete),
              onPressed: () => _delete(context, ref, customer.name),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: asyncCustomer.when(
        loading: () => const AppLoading(label: 'Loading customer…'),
        error: (error, _) => AppErrorState(
          title: 'Could not load customer',
          message: error.toString(),
          onRetry: () => ref.invalidate(customerDetailProvider(customerId)),
        ),
        data: (customer) {
          final initial = customer.name.isNotEmpty
              ? customer.name[0].toUpperCase()
              : '?';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              PremiumCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.22),
                            colorScheme.primary.withValues(alpha: 0.08),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      customer.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.phone,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          customer.phone,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Profile'),
              PremiumCard(
                child: Column(
                  children: [
                    CustomerInfoTile(
                      icon: AppIcons.security,
                      label: 'CNIC',
                      value: CustomerFormatters.displayOrDash(customer.cnic),
                    ),
                    Divider(
                      height: AppSpacing.lg,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    CustomerInfoTile(
                      icon: AppIcons.address,
                      label: 'Address',
                      value:
                          CustomerFormatters.displayOrDash(customer.address),
                    ),
                    Divider(
                      height: AppSpacing.lg,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    CustomerInfoTile(
                      icon: AppIcons.calendar,
                      label: 'Created Date',
                      value:
                          CustomerFormatters.formatDate(customer.createdAt),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Balances'),
              PremiumCard(
                child: Column(
                  children: [
                    CustomerInfoTile(
                      icon: AppIcons.money,
                      label: 'Total Amount',
                      value: CurrencyFormatter.format(customer.totalUdhaar),
                      valueColor: AppColors.udhaar,
                    ),
                    Divider(
                      height: AppSpacing.lg,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    CustomerInfoTile(
                      icon: AppIcons.received,
                      label: 'Total Received',
                      value:
                          CurrencyFormatter.format(customer.totalReceived),
                      valueColor: AppColors.received,
                    ),
                    Divider(
                      height: AppSpacing.lg,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                    CustomerInfoTile(
                      icon: AppIcons.remaining,
                      label: 'Remaining Balance',
                      value: CurrencyFormatter.format(
                        customer.remainingBalance,
                      ),
                      valueColor: AppColors.remaining,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.customerLedger,
                        arguments: customer.id,
                      ),
                      icon: const Icon(AppIcons.ledger),
                      label: const Text('Ledger'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(
                        AppRoutes.paymentHistory,
                        arguments: {
                          'customerId': customer.id,
                          'customerName': customer.name,
                        },
                      ),
                      icon: const Icon(AppIcons.payments),
                      label: const Text('Payments'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.addPayment,
                    arguments: customer.id,
                  ),
                  icon: const Icon(AppIcons.payments),
                  label: const Text('Add Payment'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(context),
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
                      onPressed: () => _delete(context, ref, customer.name),
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
