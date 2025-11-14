import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iOSSettings),
    );
  }

  Future<void> initializeCallback() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
      },
    );
  }

  /// Show immediate notification
  Future<void> show({
    required int id,
    required String title,
    String? body,
    String? imagePath, // optional image
  }) async {
    final androidDetails = imagePath != null && File(imagePath).existsSync()
        ? AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body ?? '',
            ),
          )
        : const AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

    await _plugin.show(
      id,
      title,
      body ?? '',
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Schedule notification at specific time
  Future<void> schedule({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? imagePath, // optional image
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = imagePath != null && File(imagePath).existsSync()
        ? AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body ?? '',
            ),
          )
        : const AndroidNotificationDetails(
            'reminder_channel',
            'Reminders',
            channelDescription: 'Reminder notifications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          );

    await _plugin.zonedSchedule(
      id,
      title,
      body ?? '',
      tzDate,
      NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}
