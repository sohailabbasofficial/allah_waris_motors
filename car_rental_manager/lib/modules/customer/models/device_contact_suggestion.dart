/// A phone book entry used for Add Customer autocomplete.
class DeviceContactSuggestion {
  const DeviceContactSuggestion({
    required this.name,
    required this.phone,
    required this.normalizedPhone,
  });

  final String name;
  final String phone;
  final String normalizedPhone;
}
