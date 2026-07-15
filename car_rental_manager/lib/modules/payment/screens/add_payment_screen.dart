import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/providers/customer_provider.dart';
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
    if (_customerId == null || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer and date are required')),
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
            customerId: _customerId!,
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
    final balanceAsync = _customerId == null
        ? null
        : ref.watch(customerAvailableBalanceProvider(_customerId!));
    final available = balanceAsync?.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (customers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No customers found. Add a customer first.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          PaymentForm(
            formKey: _formKey,
            customers: customers,
            selectedCustomerId: _customerId,
            onCustomerChanged: (id) => setState(() => _customerId = id),
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
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving || customers.isEmpty ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
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
