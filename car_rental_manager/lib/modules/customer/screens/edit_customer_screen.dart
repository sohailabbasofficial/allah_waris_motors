import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../repository/customer_repository.dart';
import '../widgets/customer_form.dart';

/// Updates an existing customer in SQLite.
class EditCustomerScreen extends ConsumerStatefulWidget {
  const EditCustomerScreen({super.key, required this.customerId});

  final int customerId;

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cnicController = TextEditingController();
  final _addressController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cnicController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _fillForm(CustomerModel customer) {
    if (_initialized) return;
    _nameController.text = customer.name;
    _phoneController.text = customer.phone;
    _cnicController.text = customer.cnic ?? '';
    _addressController.text = customer.address ?? '';
    _initialized = true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await ref.read(customerListProvider.notifier).updateCustomer(
            id: widget.customerId,
            name: _nameController.text,
            phone: _phoneController.text,
            cnic: _cnicController.text,
            address: _addressController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer updated successfully')),
      );
      Navigator.of(context).pop(true);
    } on DuplicatePhoneException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This phone number already exists')),
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
    final customerAsync =
        ref.watch(customerDetailProvider(widget.customerId));

    ref.listen(customerDetailProvider(widget.customerId), (previous, next) {
      next.whenData(_fillForm);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer')),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (customer) {
          _fillForm(customer);
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CustomerForm(
                formKey: _formKey,
                nameController: _nameController,
                phoneController: _phoneController,
                cnicController: _cnicController,
                addressController: _addressController,
                enabled: !_saving,
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }
}
