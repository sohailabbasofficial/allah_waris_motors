class PaymentValidationService {
  PaymentValidationService._();

  static String? validateCustomer(int? customerId) {
    if (customerId == null) return 'Please select a customer';
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) return 'Payment date is required';
    return null;
  }

  static String? validateAmount(String? value, {double? maxRemaining}) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null) return 'Enter a valid amount';
    if (amount <= 0) return 'Payment amount must be greater than 0';
    if (maxRemaining != null && amount > maxRemaining + 0.0001) {
      return 'Amount cannot exceed remaining balance';
    }
    return null;
  }
}
