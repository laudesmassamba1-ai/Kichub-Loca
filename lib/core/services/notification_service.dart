import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> showReminderNotification({
    required String title,
    required String body,
    required DateTime when,
  }) async {
    if (kIsWeb) return;

    final scheduled = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      title.hashCode,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'kichub_reminders',
          'Rappels Kichub',
          channelDescription: 'Notifications de relance terrain',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
