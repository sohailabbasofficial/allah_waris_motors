import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../customer/models/customer_model.dart';
import '../../transaction/models/transaction_model.dart';
import '../services/payment_validation_service.dart';
import 'balance_summary_card.dart';

class PaymentForm extends StatelessWidget {
  const PaymentForm({
    super.key,
    required this.formKey,
    required this.customers,
    required this.selectedCustomerId,
    required this.onCustomerChanged,
    required this.transactions,
    required this.selectedTransactionId,
    required this.onTransactionChanged,
    required this.date,
    required this.onPickDate,
    required this.amountController,
    required this.notesController,
    required this.availableBalance,
    this.enabled = true,
    this.lockCustomer = false,
    this.lockTransaction = false,
    this.customerSearch = '',
    this.onCustomerSearchChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<CustomerModel> customers;
  final int? selectedCustomerId;
  final ValueChanged<int?> onCustomerChanged;
  final List<TransactionModel> transactions;
  final int? selectedTransactionId;
  final ValueChanged<int?> onTransactionChanged;
  final DateTime? date;
  final VoidCallback onPickDate;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final double availableBalance;
  final bool enabled;
  final bool lockCustomer;
  final bool lockTransaction;
  final String customerSearch;
  final ValueChanged<String>? onCustomerSearchChanged;

  @override
  Widget build(BuildContext context) {
    final q = customerSearch.trim().toLowerCase();
    final filtered = q.isEmpty
        ? customers
        : customers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.phone.toLowerCase().contains(q),
            )
            .toList();

    final dateLabel =
        date == null ? 'Select date' : DateFormat('dd MMM yyyy').format(date!);
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!lockCustomer) ...[
            TextField(
              enabled: enabled,
              decoration: const InputDecoration(
                labelText: 'Search customer',
                prefixIcon: Icon(AppIcons.search),
              ),
              onChanged: onCustomerSearchChanged,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: selectedCustomerId,
            decoration: const InputDecoration(
              labelText: 'Customer *',
              prefixIcon: Icon(AppIcons.customer),
            ),
            items: filtered
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text('${c.name} (${c.phone})'),
                  ),
                )
                .toList(),
            onChanged: enabled && !lockCustomer ? onCustomerChanged : null,
            validator: (_) =>
                PaymentValidationService.validateCustomer(selectedCustomerId),
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: selectedTransactionId,
            decoration: const InputDecoration(
              labelText: 'Transaction *',
              prefixIcon: Icon(AppIcons.transactions),
            ),
            items: transactions
                .map(
                  (t) => DropdownMenuItem<int>(
                    value: t.id,
                    child: Text(
                      '${DateFormat('dd MMM').format(t.date)} · '
                      '${t.description} · due ${t.remainingAmount.toStringAsFixed(0)}',
                    ),
                  ),
                )
                .toList(),
            onChanged:
                enabled && !lockTransaction ? onTransactionChanged : null,
            validator: (value) =>
                value == null ? 'Transaction is required' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectedTransactionId != null)
            BalanceSummaryCard(remainingBalance: availableBalance),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPickDate : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Payment Date *',
                  prefixIcon: const Icon(AppIcons.calendar),
                  suffixIcon: Icon(
                    AppIcons.chevron,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: date == null
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: amountController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Payment Amount *',
              prefixIcon: Icon(AppIcons.money),
            ),
            validator: (value) => PaymentValidationService.validateAmount(
              value,
              maxRemaining: availableBalance,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: notesController,
            enabled: enabled,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(AppIcons.notes),
            ),
          ),
        ],
      ),
    );
  }
}
