import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder_model.dart';
import '../services/db_service.dart';
import '../services/notification_handler.dart';

final reminderProvider =
    StateNotifierProvider<ReminderNotifier, AsyncValue<List<ReminderModel>>>(
  (ref) => ReminderNotifier(),
);

class ReminderNotifier extends StateNotifier<AsyncValue<List<ReminderModel>>> {
  ReminderNotifier() : super(const AsyncValue.loading()) {
    loadReminders();
  }

  final NotificationHandler _notificationHandler = NotificationHandler();

  /// Load reminders from DB and disable expired ones
  Future<void> loadReminders() async {
    try {
      await _notificationHandler.init();
      final reminders = await DBService.getReminders();
      final now = DateTime.now();

      final updatedReminders = reminders.map((reminder) {
        if (reminder.enabled && reminder.reminderTime.isBefore(now)) {
          final disabledReminder = reminder.copyWith(enabled: false);
          DBService.updateReminder(disabledReminder);
          return disabledReminder;
        }
        return reminder;
      }).toList();

      state = AsyncValue.data(updatedReminders);
      await _scheduleAllNotifications(updatedReminders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Schedule all active reminders
  Future<void> _scheduleAllNotifications(List<ReminderModel> reminders) async {
    for (final reminder in reminders) {
      if (reminder.enabled && reminder.reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(reminder);
      }
    }
  }

  /// Schedule a single reminder via NotificationHandler
  Future<void> _scheduleNotification(ReminderModel reminder) async {
    final id = int.tryParse(reminder.id) ?? reminder.id.hashCode;

    // Use treatment as notification body if available, otherwise null
    final body = (reminder.treatment != null && reminder.treatment!.isNotEmpty)
        ? reminder.treatment
        : null;

    await _notificationHandler.schedule(
      id: id,
      title: reminder.title,
      body: body,
      scheduledDate: reminder.reminderTime,
      imagePath: reminder.imagePath, // pass image if available
    );
  }

  /// Add a new reminder
  Future<void> addReminder(ReminderModel reminder) async {
    try {
      await DBService.insertReminder(reminder);
      await loadReminders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update an existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await DBService.updateReminder(reminder);
      await _notificationHandler.cancel(
        int.tryParse(reminder.id) ?? reminder.id.hashCode,
      );
      if (reminder.enabled) {
        await _scheduleNotification(reminder);
      }
      await loadReminders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    try {
      await _notificationHandler.cancel(int.tryParse(id) ?? id.hashCode);
      await DBService.deleteReminder(id);
      await loadReminders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggle reminder enabled/disabled
  Future<void> toggleReminder(String id) async {
    try {
      final reminders = await DBService.getReminders();
      final reminder = reminders.firstWhere((r) => r.id == id);

      final updatedReminder = reminder.copyWith(enabled: !reminder.enabled);
      await DBService.updateReminder(updatedReminder);

      if (updatedReminder.enabled &&
          updatedReminder.reminderTime.isAfter(DateTime.now())) {
        await _scheduleNotification(updatedReminder);
      } else {
        await _notificationHandler.cancel(int.tryParse(id) ?? id.hashCode);
      }

      await loadReminders();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
