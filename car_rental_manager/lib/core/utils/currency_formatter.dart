import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

/// Formats amounts as Pakistani-style currency: Rs. 250,000
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _number = NumberFormat('#,##0.##');

  static String format(num amount) {
    return '${AppConstants.currencySymbol} ${_number.format(amount)}';
  }
}
