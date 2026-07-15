import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/premium_card.dart';
import '../../customer/providers/customer_provider.dart';
import '../../transaction/providers/transaction_provider.dart';
import '../providers/payment_provider.dart';
import '../repository/payment_repository.dart';
import '../widgets/payment_form.dart';

class AddPaymentScreen extends ConsumerStatefulWidget {
  const AddPaymentScreen({super.key, this.preselectedCustomerId});

  final int? preselectedCustomerId;

  @override
  ConsumerState<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends ConsumerState<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _customerId;
  int? _transactionId;
  DateTime? _date = DateTime.now();
  String _customerSearch = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customerId = widget.preselectedCustomerId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_transactionId == null || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction and date are required')),
      );
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving payments requires Android/iOS/desktop.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(paymentListProvider.notifier).add(
            transactionId: _transactionId!,
            paymentDate: _date!,
            paymentAmount: double.parse(_amountController.text.trim()),
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment saved successfully')),
      );
      Navigator.of(context).pop(true);
    } on PaymentExceedsBalanceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customers =
        ref.watch(customerListProvider).valueOrNull?.customers ?? [];
    final openTxAsync = _customerId == null
        ? null
        : ref.watch(openTransactionsProvider(_customerId!));
    final transactions = openTxAsync?.valueOrNull ?? [];
    final balanceAsync = _transactionId == null
        ? null
        : ref.watch(transactionAvailableBalanceProvider(_transactionId!));
    final available = balanceAsync?.valueOrNull ?? 0;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          if (customers.isEmpty)
            PremiumCard(
              color: scheme.errorContainer.withValues(alpha: 0.45),
              child: Row(
                children: [
                  Icon(AppIcons.warning, color: scheme.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'No customers found. Add a customer first.',
                      style: TextStyle(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (customers.isEmpty) const SizedBox(height: AppSpacing.lg),
          PaymentForm(
            formKey: _formKey,
            customers: customers,
            selectedCustomerId: _customerId,
            onCustomerChanged: (id) => setState(() {
              _customerId = id;
              _transactionId = null;
            }),
            transactions: transactions,
            selectedTransactionId: _transactionId,
            onTransactionChanged: (id) => setState(() => _transactionId = id),
            date: _date,
            onPickDate: _pickDate,
            amountController: _amountController,
            notesController: _notesController,
            availableBalance: available,
            enabled: !_saving,
            lockCustomer: widget.preselectedCustomerId != null,
            customerSearch: _customerSearch,
            onCustomerSearchChanged: (value) =>
                setState(() => _customerSearch = value),
          ),
          if (_customerId != null &&
              openTxAsync?.hasValue == true &&
              transactions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: PremiumCard(
                color: scheme.errorContainer.withValues(alpha: 0.35),
                child: Row(
                  children: [
                    Icon(AppIcons.info, color: scheme.error),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'This customer has no open transactions to pay against.',
                        style: TextStyle(
                          color: scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving || transactions.isEmpty ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.save),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
