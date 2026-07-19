/// Phone number normalization for contact ↔ customer matching.
class PhoneNormalizer {
  PhoneNormalizer._();

  /// Digits-only form with Pakistan-friendly country-code handling.
  ///
  /// Examples:
  /// - `+92 301-1234567` → `03011234567`
  /// - `00923011234567` → `03011234567`
  /// - `92 301 1234567` → `03011234567`
  static String normalize(String? raw) {
    if (raw == null) return '';
    var phone = raw.trim().replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
    if (phone.isEmpty) return '';

    if (phone.startsWith('+92')) {
      phone = '0${phone.substring(3)}';
    } else if (phone.startsWith('0092')) {
      phone = '0${phone.substring(4)}';
    } else if (phone.startsWith('92') && phone.length >= 12) {
      phone = '0${phone.substring(2)}';
    }

    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Lookup keys used for fuzzy matching (full number + last 10 digits).
  static Set<String> matchKeys(String? raw) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) return const {};

    final keys = <String>{normalized};
    if (normalized.length > 10) {
      keys.add(normalized.substring(normalized.length - 10));
    } else if (normalized.length == 10) {
      keys.add(normalized);
      keys.add('0$normalized');
    }
    return keys;
  }
}
