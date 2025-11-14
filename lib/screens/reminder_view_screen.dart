import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/text_provider.dart';
import 'reminder_edit_screen.dart';

class ReminderViewScreen extends ConsumerStatefulWidget {
  final ReminderModel reminder;
  const ReminderViewScreen({super.key, required this.reminder});

  @override
  ConsumerState<ReminderViewScreen> createState() => _ReminderViewScreenState();
}

class _ReminderViewScreenState extends ConsumerState<ReminderViewScreen> {
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

  String _getRepeatText(ReminderModel reminder) {
    if (reminder.repeat == 'none')
      return ref.read(currentTextProvider('norepeat'));
    if (reminder.repeat == 'daily')
      return ref.read(currentTextProvider('daily'));
    return ref.read(currentTextProvider('custom'));
  }

  Widget _buildSectionCard({
    required String title,
    required String content,
    Color titleColor = Colors.black,
    Color contentColor = Colors.black87,
    Color surfaceTintColor = Colors.black,
  }) {
    if (content.isEmpty) return const SizedBox.shrink();
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      surfaceTintColor: surfaceTintColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: titleColor,
                ),
              ),
            const SizedBox(height: 6),
            Text(content, style: TextStyle(fontSize: 14, color: contentColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminder = widget.reminder;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.read(currentTextProvider('reminderDetails')) ??
              'Reminder Details',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditReminderScreen(reminder: reminder),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            reminder.imagePath != null && File(reminder.imagePath!).existsSync()
                ? Image.file(
                    File(reminder.imagePath!),
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.alarm, size: 100, color: Colors.green),
            const SizedBox(height: 20),
            _buildSectionCard(
              title: ref.read(currentTextProvider('title')) ?? 'Title',
              content: reminder.title,
              titleColor: Colors.red,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode ? Colors.red : Colors.redAccent,
            ),
            _buildSectionCard(
              title:
                  ref.read(currentTextProvider('description')) ?? 'Description',
              content: reminder.description ?? '',
              titleColor: isDarkMode
                  ? Colors.yellow.shade700
                  : Colors.yellow.shade900,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode
                  ? Colors.yellow
                  : Colors.yellowAccent,
            ),
            _buildSectionCard(
              title: ref.read(currentTextProvider('time')) ?? 'Time',
              content: _formatTime(reminder.reminderTime),
              titleColor: Colors.deepOrange.shade800,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode
                  ? Colors.red.shade500
                  : Colors.red.shade100,
            ),
            _buildSectionCard(
              title: ref.read(currentTextProvider('repeat')) ?? 'Repeat',
              content: _getRepeatText(reminder),
              titleColor: Colors.deepOrange.shade400,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode
                  ? Colors.orangeAccent
                  : Colors.deepPurpleAccent,
            ),
            _buildSectionCard(
              title: ref.read(currentTextProvider('cause')) ?? 'Cause',
              content: reminder.cause ?? '',
              titleColor: isDarkMode ? Colors.cyanAccent : Colors.blue,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode
                  ? Colors.blue
                  : Colors.lightBlueAccent,
            ),
            _buildSectionCard(
              title: ref.read(currentTextProvider('symptoms')) ?? 'Symptoms',
              content: reminder.symptoms ?? '',
              titleColor: isDarkMode
                  ? Colors.pinkAccent.shade100
                  : Colors.pinkAccent.shade700,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode ? Colors.pink : Colors.pinkAccent,
            ),
            _buildSectionCard(
              title:
                  ref.read(currentTextProvider('prevention')) ?? 'Prevention',
              content: reminder.prevention ?? '',
              titleColor: isDarkMode ? Colors.amberAccent : Colors.orange,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode
                  ? Colors.yellow.shade900
                  : Colors.amberAccent,
            ),
            _buildSectionCard(
              title: ref.read(currentTextProvider('treatment')) ?? 'Treatment',
              content: reminder.treatment ?? '',
              titleColor: isDarkMode
                  ? Colors.green.shade200
                  : Colors.green.shade400,
              contentColor: isDarkMode ? Colors.white70 : Colors.black87,
              surfaceTintColor: isDarkMode ? Colors.green : Colors.lightGreen,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
