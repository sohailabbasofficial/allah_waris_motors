import 'package:intl/intl.dart';

/// Formatting helpers for customer UI.
class CustomerFormatters {
  CustomerFormatters._();

  static final DateFormat _date = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDate(DateTime date) => _date.format(date);

  static String displayOrDash(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '-';
    return text;
  }
}
