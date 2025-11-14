import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

class NotificationHandler {
  static final NotificationHandler _instance = NotificationHandler._internal();
  factory NotificationHandler() => _instance;
  NotificationHandler._internal();

  final NotificationService _service = NotificationService();

  /// Initialize notifications and request permissions
  Future<void> init() async {
    await _service.init();
    await _requestPermissions();
    await _service.initializeCallback();
  }

  Future<void> _requestPermissions() async {
    final notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) {
      print('Notification permission denied.');
    }

    if (await Permission.scheduleExactAlarm.isGranted == false) {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      if (!alarmStatus.isGranted) {
        print('Exact alarm permission denied.');
      }
    }
  }

  /// Schedule a reminder notification
  Future<void> schedule({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? imagePath, // optional image
  }) async {
    await _service.schedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      imagePath: imagePath,
    );
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async => _service.cancel(id);

  /// Cancel all notifications
  Future<void> cancelAll() async => _service.cancelAll();

  /// Show an immediate notification
  Future<void> show({
    required int id,
    required String title,
    String? body,
    String? imagePath,
  }) async {
    try {
      await _service.show(
        id: id,
        title: title,
        body: body,
        imagePath: imagePath,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }
}
