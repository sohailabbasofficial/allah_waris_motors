import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/device_contact_suggestion.dart';
import '../services/customer_validation_service.dart';
import 'phone_autocomplete_field.dart';

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
    this.enablePhoneSuggestions = false,
    this.onPhoneContactSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController cnicController;
  final TextEditingController addressController;
  final bool enabled;

  /// When true (Add Customer), shows phone autocomplete from mobile contacts.
  final bool enablePhoneSuggestions;
  final ValueChanged<DeviceContactSuggestion>? onPhoneContactSelected;

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
              prefixIcon: Icon(AppIcons.customer),
            ),
            validator: CustomerValidationService.validateName,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (enablePhoneSuggestions)
            PhoneAutocompleteField(
              controller: phoneController,
              enabled: enabled,
              onContactSelected: onPhoneContactSelected,
            )
          else
            TextFormField(
              controller: phoneController,
              enabled: enabled,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                prefixIcon: Icon(AppIcons.phone),
              ),
              validator: CustomerValidationService.validatePhone,
              textInputAction: TextInputAction.next,
            ),
          const SizedBox(height: AppSpacing.lg),
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
              prefixIcon: Icon(AppIcons.security),
              hintText: '13-digit CNIC',
            ),
            validator: CustomerValidationService.validateCnic,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: addressController,
            enabled: enabled,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Address (optional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(AppIcons.address),
            ),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }
}
