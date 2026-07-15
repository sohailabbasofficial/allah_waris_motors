import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/constants/app_constants.dart';

/// Local notifications for automatic backup results.
class BackupNotificationService {
  BackupNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  Future<void> initialize() async {
    if (kIsWeb || _ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  Future<void> notifyBackupResult({
    required bool success,
    required String message,
  }) async {
    if (kIsWeb) return;
    try {
      await initialize();
      const androidDetails = AndroidNotificationDetails(
        'backup_channel',
        'Backup',
        channelDescription: 'Automatic backup notifications',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        id: success ? 2001 : 2002,
        title: success
            ? '${AppConstants.appName}: Backup complete'
            : '${AppConstants.appName}: Backup failed',
        body: message,
        notificationDetails: details,
      );
    } catch (_) {
      // Notifications are best-effort on unsupported desktops.
    }
  }
}
