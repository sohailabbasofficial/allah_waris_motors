import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
import '../../customer/providers/customer_provider.dart';
import '../../transaction/models/transaction_model.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../repository/payment_repository.dart';
import '../widgets/payment_form.dart';

class EditPaymentScreen extends ConsumerStatefulWidget {
  const EditPaymentScreen({super.key, required this.paymentId});

  final int paymentId;

  @override
  ConsumerState<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends ConsumerState<EditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  int? _customerId;
  int? _transactionId;
  DateTime? _date;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _fill(PaymentModel payment) {
    if (_initialized) return;
    _customerId = payment.customerId;
    _transactionId = payment.transactionId;
    _date = payment.paymentDate;
    _amountController.text = payment.paymentAmount.toStringAsFixed(
      payment.paymentAmount % 1 == 0 ? 0 : 2,
    );
    _notesController.text = payment.notes ?? '';
    _initialized = true;
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
    if (_date == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(paymentListProvider.notifier).updatePayment(
            id: widget.paymentId,
            paymentDate: _date!,
            paymentAmount: double.parse(_amountController.text.trim()),
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment updated successfully')),
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
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(paymentDetailProvider(widget.paymentId));
    final customers =
        ref.watch(customerListProvider).valueOrNull?.customers ?? [];

    ref.listen(paymentDetailProvider(widget.paymentId), (_, next) {
      next.whenData(_fill);
    });

    final available = _transactionId == null
        ? 0.0
        : ref
                .watch(
                  editableAvailableBalanceProvider(
                    (
                      transactionId: _transactionId!,
                      excludePaymentId: widget.paymentId,
                    ),
                  ),
                )
                .valueOrNull ??
            0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Payment')),
      body: paymentAsync.when(
        loading: () => const AppLoading(label: 'Loading payment…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load payment',
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(paymentDetailProvider(widget.paymentId)),
        ),
        data: (payment) {
          _fill(payment);
          final tx = TransactionModel(
            id: payment.transactionId,
            customerId: payment.customerId,
            customerName: payment.customerName,
            date: payment.paymentDate,
            description: 'Linked transaction #${payment.transactionId}',
            totalAmount: 0,
            receivedAmount: 0,
            remainingAmount: available,
            createdAt: payment.createdAt,
            updatedAt: payment.updatedAt ?? payment.createdAt,
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              PaymentForm(
                formKey: _formKey,
                customers: customers,
                selectedCustomerId: _customerId,
                onCustomerChanged: (_) {},
                transactions: [tx],
                selectedTransactionId: _transactionId,
                onTransactionChanged: (_) {},
                date: _date,
                onPickDate: _pickDate,
                amountController: _amountController,
                notesController: _notesController,
                availableBalance: available,
                enabled: !_saving,
                lockCustomer: true,
                lockTransaction: true,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
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
          );
        },
      ),
    );
  }
}
