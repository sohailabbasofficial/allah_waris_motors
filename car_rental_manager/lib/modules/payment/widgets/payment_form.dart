import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../customer/models/customer_model.dart';
import '../services/payment_validation_service.dart';
import 'balance_summary_card.dart';

class PaymentForm extends StatelessWidget {
  const PaymentForm({
    super.key,
    required this.formKey,
    required this.customers,
    required this.selectedCustomerId,
    required this.onCustomerChanged,
    required this.date,
    required this.onPickDate,
    required this.amountController,
    required this.notesController,
    required this.availableBalance,
    this.enabled = true,
    this.lockCustomer = false,
    this.customerSearch = '',
    this.onCustomerSearchChanged,
  });

  final GlobalKey<FormState> formKey;
  final List<CustomerModel> customers;
  final int? selectedCustomerId;
  final ValueChanged<int?> onCustomerChanged;
  final DateTime? date;
  final VoidCallback onPickDate;
  final TextEditingController amountController;
  final TextEditingController notesController;
  final double availableBalance;
  final bool enabled;
  final bool lockCustomer;
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
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: onCustomerSearchChanged,
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: selectedCustomerId,
            decoration: const InputDecoration(
              labelText: 'Customer *',
              prefixIcon: Icon(Icons.person_outline),
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
          const SizedBox(height: 12),
          if (selectedCustomerId != null)
            BalanceSummaryCard(remainingBalance: availableBalance),
          const SizedBox(height: 16),
          InkWell(
            onTap: enabled ? onPickDate : null,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Payment Date *',
                prefixIcon: Icon(Icons.calendar_month_outlined),
              ),
              child: Text(dateLabel),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amountController,
            enabled: enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Payment Amount *',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (value) => PaymentValidationService.validateAmount(
              value,
              maxRemaining: availableBalance,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            enabled: enabled,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
