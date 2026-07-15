import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_states.dart';
import '../../customer/providers/customer_provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../services/transaction_validation_service.dart';
import '../widgets/transaction_form.dart';

class EditTransactionScreen extends ConsumerStatefulWidget {
  const EditTransactionScreen({super.key, required this.transactionId});

  final int transactionId;

  @override
  ConsumerState<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends ConsumerState<EditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _receivedController = TextEditingController();
  final _notesController = TextEditingController();

  int? _customerId;
  DateTime? _date;
  String? _description;
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _totalController.addListener(_onAmountChanged);
    _receivedController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _totalController
      ..removeListener(_onAmountChanged)
      ..dispose();
    _receivedController
      ..removeListener(_onAmountChanged)
      ..dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAmountChanged() => setState(() {});

  double get _remaining {
    final total = double.tryParse(_totalController.text.trim()) ?? 0;
    final received = double.tryParse(_receivedController.text.trim()) ?? 0;
    return TransactionValidationService.remaining(total, received);
  }

  void _fill(TransactionModel tx) {
    if (_initialized) return;
    _customerId = tx.customerId;
    _date = tx.date;
    _description = tx.description;
    _totalController.text = tx.totalAmount.toStringAsFixed(
      tx.totalAmount % 1 == 0 ? 0 : 2,
    );
    _receivedController.text = tx.receivedAmount.toStringAsFixed(
      tx.receivedAmount % 1 == 0 ? 0 : 2,
    );
    _notesController.text = tx.notes ?? '';
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
    if (_date == null || _customerId == null || _description == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(transactionListProvider.notifier).updateTransaction(
            id: widget.transactionId,
            customerId: _customerId!,
            date: _date!,
            description: _description!,
            totalAmount: double.parse(_totalController.text.trim()),
            receivedAmount: double.parse(_receivedController.text.trim()),
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction updated successfully')),
      );
      Navigator.of(context).pop(true);
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
    final txAsync = ref.watch(transactionDetailProvider(widget.transactionId));
    final customers =
        ref.watch(customerListProvider).valueOrNull?.customers ?? [];

    ref.listen(transactionDetailProvider(widget.transactionId), (_, next) {
      next.whenData(_fill);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: txAsync.when(
        loading: () => const AppLoading(label: 'Loading transaction…'),
        error: (e, _) => AppErrorState(
          title: 'Could not load transaction',
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(transactionDetailProvider(widget.transactionId)),
        ),
        data: (tx) {
          _fill(tx);
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              TransactionForm(
                formKey: _formKey,
                customers: customers,
                selectedCustomerId: _customerId,
                onCustomerChanged: (id) => setState(() => _customerId = id),
                date: _date,
                onPickDate: _pickDate,
                description: _description,
                onDescriptionChanged: (value) =>
                    setState(() => _description = value),
                totalController: _totalController,
                receivedController: _receivedController,
                notesController: _notesController,
                remainingAmount: _remaining,
                enabled: !_saving,
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
