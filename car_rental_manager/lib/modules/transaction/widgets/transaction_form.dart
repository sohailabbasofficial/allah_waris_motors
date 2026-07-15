import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../customer/models/customer_model.dart';
import '../services/transaction_validation_service.dart';
import 'amount_summary_card.dart';

/// Shared add/edit transaction form with live remaining calculation.
class TransactionForm extends StatelessWidget {
  const TransactionForm({
    super.key,
    required this.formKey,
    required this.customers,
    required this.selectedCustomerId,
    required this.onCustomerChanged,
    required this.date,
    required this.onPickDate,
    required this.description,
    required this.onDescriptionChanged,
    required this.totalController,
    required this.receivedController,
    required this.notesController,
    required this.remainingAmount,
    this.enabled = true,
    this.lockCustomer = false,
  });

  final GlobalKey<FormState> formKey;
  final List<CustomerModel> customers;
  final int? selectedCustomerId;
  final ValueChanged<int?> onCustomerChanged;
  final DateTime? date;
  final VoidCallback onPickDate;
  final String? description;
  final ValueChanged<String?> onDescriptionChanged;
  final TextEditingController totalController;
  final TextEditingController receivedController;
  final TextEditingController notesController;
  final double remainingAmount;
  final bool enabled;
  final bool lockCustomer;

  @override
  Widget build(BuildContext context) {
    final total = double.tryParse(totalController.text.trim()) ?? 0;
    final received = double.tryParse(receivedController.text.trim()) ?? 0;
    final dateLabel = date == null
        ? 'Select date'
        : DateFormat('dd MMM yyyy').format(date!);
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: selectedCustomerId,
            decoration: const InputDecoration(
              labelText: 'Customer *',
              prefixIcon: Icon(AppIcons.customer),
            ),
            items: customers
                .map(
                  (c) => DropdownMenuItem<int>(
                    value: c.id,
                    child: Text('${c.name} (${c.phone})'),
                  ),
                )
                .toList(),
            onChanged: enabled && !lockCustomer ? onCustomerChanged : null,
            validator: (_) =>
                TransactionValidationService.validateCustomer(selectedCustomerId),
          ),
          const SizedBox(height: AppSpacing.lg),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPickDate : null,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date *',
                  prefixIcon: const Icon(AppIcons.calendar),
                  suffixIcon: Icon(
                    AppIcons.chevron,
                    color: scheme.onSurfaceVariant,
                  ),
                  errorText: TransactionValidationService.validateDate(date),
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
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: description,
            decoration: const InputDecoration(
              labelText: 'Description *',
              prefixIcon: Icon(AppIcons.transactions),
            ),
            items: TransactionValidationService.descriptions
                .map(
                  (d) => DropdownMenuItem<String>(
                    value: d,
                    child: Text(d),
                  ),
                )
                .toList(),
            onChanged: enabled ? onDescriptionChanged : null,
            validator: TransactionValidationService.validateDescription,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: totalController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Total Amount *',
              prefixIcon: Icon(AppIcons.money),
            ),
            validator: TransactionValidationService.validateTotalAmount,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: receivedController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Received Amount *',
              prefixIcon: Icon(AppIcons.received),
            ),
            validator: (value) =>
                TransactionValidationService.validateReceivedAmount(
              value,
              totalController.text,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Remaining Amount',
              prefixIcon: Icon(AppIcons.remaining),
              helperText: 'Auto-calculated (Total - Received)',
            ),
            child: Text(
              remainingAmount.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AmountSummaryCard(
            totalAmount: total,
            receivedAmount: received,
            remainingAmount: remainingAmount,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: notesController,
            enabled: enabled,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
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
