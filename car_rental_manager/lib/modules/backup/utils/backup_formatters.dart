import 'package:intl/intl.dart';

class BackupFormatters {
  BackupFormatters._();

  static final _dateTime = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatDateTime(DateTime? value) {
    if (value == null) return 'Never';
    return _dateTime.format(value);
  }

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '-';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
