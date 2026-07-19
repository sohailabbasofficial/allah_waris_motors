/// Validation helpers for transaction forms.
class TransactionValidationService {
  TransactionValidationService._();

  static const descriptions = <String>[
    'Car Rent',
    'Advance',
    'Fine',
    'Fuel Charges',
    'Maintenance',
    'Other',
  ];

  static String? validateCustomer(int? customerId) {
    if (customerId == null) return 'Please select a customer';
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) return 'Date is required';
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  static String? validateTotalAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Total amount must be greater than zero';
    return null;
  }

  static String? validateReceivedAmount(String? value, String? totalText) {
    final received = double.tryParse(value?.trim() ?? '');
    final total = double.tryParse(totalText?.trim() ?? '') ?? 0;
    if (received == null) return 'Enter a valid amount';
    if (received < 0) return 'Received amount cannot be negative';
    if (received > total) {
      return 'Received amount cannot exceed total amount';
    }
    return null;
  }

  /// Validates an additional charge added onto an existing transaction.
  static String? validateAddedAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Amount is required';
    final amount = double.tryParse(text);
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Amount must be greater than zero';
    return null;
  }

  static double remaining(double total, double received) {
    final value = total - received;
    return value < 0 ? 0 : value;
  }
}
