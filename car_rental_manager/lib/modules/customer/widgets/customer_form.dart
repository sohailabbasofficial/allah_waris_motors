import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/customer_validation_service.dart';

/// Shared add/edit customer form fields.
class CustomerForm extends StatelessWidget {
  const CustomerForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.cnicController,
    required this.addressController,
    this.enabled = true,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnicController;
  final TextEditingController addressController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            enabled: enabled,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Customer Name *',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: CustomerValidationService.validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            enabled: enabled,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone Number *',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: CustomerValidationService.validatePhone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: cnicController,
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: const InputDecoration(
              labelText: 'CNIC (optional)',
              prefixIcon: Icon(Icons.badge_outlined),
              hintText: '13-digit CNIC',
            ),
            validator: CustomerValidationService.validateCnic,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            enabled: enabled,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Address (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
