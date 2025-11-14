import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../providers/text_provider.dart';
import '../providers/settings_provider.dart';
import 'reminder_edit_screen.dart';
import 'reminder_view_screen.dart';
import '../models/reminder_model.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  @override
  void initState() {
    super.initState();
  }

  bool _isReminderActive(ReminderModel reminder) {
    final now = DateTime.now();
    if (reminder.repeat == 'none') {
      final reminderTimeToday = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.reminderTime.hour,
        reminder.reminderTime.minute,
      );
      if (reminderTimeToday.isBefore(now)) return false;
    }
    return reminder.enabled;
  }

  /// Get repeat text
  String _getRepeatText(ReminderModel reminder) {
    if (reminder.repeat == 'none')
      return ref.read(currentTextProvider('norepeat'));
    if (reminder.repeat == 'daily')
      return ref.read(currentTextProvider('daily'));
    return ref.read(currentTextProvider('custom')); // localized custom
  }

  /// Convert time to Nepali digits if needed
  String _formatTime(DateTime time) {
    final currentLocale = ref.watch(localeProvider);
    String formatted = DateFormat('HH:mm').format(time);
    if (currentLocale.languageCode == 'ne') {
      const en = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const ne = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
      for (int i = 0; i < 10; i++) {
        formatted = formatted.replaceAll(en[i], ne[i]);
      }
    }
    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    final remindersAsync = ref.watch(reminderProvider);
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.read(currentTextProvider('reminders'))),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (reminders) => reminders.isEmpty
            ? Center(child: Text(ref.read(currentTextProvider('noReminders'))))
            : ListView.builder(
                itemCount: reminders.length,
                itemBuilder: (context, index) {
                  final reminder = reminders[index];
                  final active = _isReminderActive(reminder);
                  final cardColor = isDarkMode
                      ? Colors.green.shade900
                      : Colors.green.shade50;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: cardColor,
                    child: ListTile(
                      leading:
                          reminder.imagePath != null &&
                              File(reminder.imagePath!).existsSync()
                          ? Image.file(
                              File(reminder.imagePath!),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : const Icon(Icons.alarm, size: 50),
                      title: Text(
                        reminder.title,
                        style: TextStyle(color: active ? null : Colors.grey),
                      ),
                      subtitle: Text(
                        '${_formatTime(reminder.reminderTime)} | ${_getRepeatText(reminder)}',
                        style: TextStyle(color: active ? null : Colors.grey),
                      ),
                      trailing: Switch(
                        value: active,
                        onChanged: (value) {
                          final now = DateTime.now();
                          final reminderTimeToday = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            reminder.reminderTime.hour,
                            reminder.reminderTime.minute,
                          );
                          if (reminder.repeat != 'none' ||
                              reminderTimeToday.isAfter(now) ) {
                            ref
                                .read(reminderProvider.notifier)
                                .toggleReminder(reminder.id);
                          }
                        },
                        activeColor: isDarkMode ? Colors.white : Colors.green,
                        inactiveThumbColor: Colors.grey[50],
                        inactiveTrackColor: Colors.grey,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ReminderViewScreen(reminder: reminder),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditReminderScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
