import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/providers/customer_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/transaction_validation_service.dart';
import '../widgets/transaction_form.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _totalController = TextEditingController();
  final _receivedController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  int? _customerId;
  DateTime? _date = DateTime.now();
  String? _description;
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

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving transactions requires Android/iOS/desktop.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(transactionListProvider.notifier).add(
            customerId: _customerId!,
            date: _date!,
            description: _description!,
            totalAmount: double.parse(_totalController.text.trim()),
            receivedAmount: double.parse(_receivedController.text.trim()),
            notes: _notesController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully')),
      );
      Navigator.of(context).pop(true);
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
    final customersAsync = ref.watch(customerListProvider);
    final customers = customersAsync.valueOrNull?.customers ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (customers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No customers found. Add a customer first.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
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
