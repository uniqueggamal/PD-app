import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';
import 'reminder_edit_screen.dart';
import 'reminder_view_screen.dart';
import '../../models/reminder_model.dart';
import '../../widgets/app_drawer.dart';

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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      colors: isDark
          ? [Colors.grey[700]!, Colors.grey[900]!]
          : [Colors.green[100]!, Colors.green[200]!, Colors.green[500]!],
    );

    final textColor = isDark ? Colors.white : Colors.white70;
    final subtitleColor = isDark ? Colors.grey[300] : Colors.white70;
    final cardColor = isDark ? Colors.grey[700] : Colors.green[50];

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.read(currentTextProvider('reminders'))),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: remindersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (reminders) => reminders.isEmpty
                      ? Center(
                          child: Text(
                            ref.read(currentTextProvider('noReminders')),
                          ),
                        )
                      : ListView.builder(
                          itemCount: reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = reminders[index];
                            final active = _isReminderActive(reminder);

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
                                  style: TextStyle(
                                    color: active ? textColor : Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  '${_formatTime(reminder.reminderTime)} | ${_getRepeatText(reminder)}',
                                  style: TextStyle(
                                    color: active ? subtitleColor : Colors.grey,
                                  ),
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
                                        reminderTimeToday.isAfter(now)) {
                                      ref
                                          .read(reminderProvider.notifier)
                                          .toggleReminder(reminder.id);
                                    }
                                  },
                                  activeColor: isDark
                                      ? Colors.white
                                      : Colors.green,
                                  inactiveThumbColor: Colors.grey[50],
                                  inactiveTrackColor: Colors.grey,
                                ),
                                onTap: () => context.go(
                                  '/reminder/view',
                                  extra: reminder,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/reminder/edit'),
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
