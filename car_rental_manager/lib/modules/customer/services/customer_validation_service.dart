/// Validation helpers for customer forms.
class CustomerValidationService {
  CustomerValidationService._();

  static String? validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Customer name is required';
    if (name.length < 2) return 'Enter at least 2 characters';
    return null;
  }

  static String? validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Phone number is required';
    if (phone.length < 7) return 'Enter a valid phone number';
    return null;
  }

  static String? validateCnic(String? value) {
    final cnic = value?.trim() ?? '';
    if (cnic.isEmpty) return null;
    final digits = cnic.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 13) return 'CNIC should be 13 digits';
    return null;
  }
}
