import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/reminder_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/text_provider.dart';
import '../../providers/localization_provider.dart';
import 'reminder_edit_screen.dart';

class ReminderViewScreen extends ConsumerWidget {
  final ReminderModel reminder;
  const ReminderViewScreen({super.key, required this.reminder});

  /// Convert time to Nepali digits if needed
  String _formatTime(DateTime time, WidgetRef ref) {
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

  String _getRepeatText(ReminderModel reminder, WidgetRef ref) {
    if (reminder.repeat == 'none')
      return ref.read(currentTextProvider('norepeat')) ?? 'No Repeat';
    if (reminder.repeat == 'daily')
      return ref.read(currentTextProvider('daily')) ?? 'Daily';
    return ref.read(currentTextProvider('custom')) ?? 'Custom';
  }

  Widget _buildInfoCard(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final cardColor = isDark ? Colors.grey[700] : Colors.green[50];
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReminderDetails(
    BuildContext context,
    ReminderModel reminder,
    WidgetRef ref,
  ) {
    final fields = [
      {
        'key': 'title',
        'fallback': 'Title',
        'icon': Icons.title,
        'content': reminder.title,
      },
      {
        'key': 'description',
        'fallback': 'Description',
        'icon': Icons.article,
        'content': reminder.description ?? '',
      },
      {
        'key': 'time',
        'fallback': 'Time',
        'icon': Icons.schedule,
        'content': _formatTime(reminder.reminderTime, ref),
      },
      {
        'key': 'repeat',
        'fallback': 'Repeat',
        'icon': Icons.repeat,
        'content': _getRepeatText(reminder, ref),
      },
      {
        'key': 'cause',
        'fallback': 'Cause',
        'icon': Icons.coronavirus,
        'content': reminder.cause ?? '',
      },
      {
        'key': 'symptoms',
        'fallback': 'Symptoms',
        'icon': Icons.monitor_heart,
        'content': reminder.symptoms ?? '',
      },
      {
        'key': 'prevention',
        'fallback': 'Prevention',
        'icon': Icons.shield,
        'content': reminder.prevention ?? '',
      },
      {
        'key': 'treatment',
        'fallback': 'Treatment',
        'icon': Icons.medical_services,
        'content': reminder.treatment ?? '',
      },
    ];

    return fields
        .where((f) => (f['content'] as String).isNotEmpty)
        .map(
          (f) => _buildInfoCard(
            context,
            ref,
            icon: f['icon'] as IconData,
            title:
                ref.read(currentTextProvider(f['key'] as String)) ??
                f['fallback'] as String,
            content: f['content'] as String,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final backgroundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [Colors.grey[850]!, Colors.grey[900]!, Colors.black87]
          : [Colors.green[50]!, Colors.green[100]!, Colors.green[200]!],
    );

    final textColor = isDark ? Colors.white : Colors.green[900]!;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.green[700]!;
    final cardColor = isDark ? Colors.grey[700] : Colors.green[50];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminder Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reminders'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/reminder/edit', extra: reminder),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Image
                  Card(
                    color: cardColor,
                    elevation: isDark ? 2 : 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child:
                          reminder.imagePath != null &&
                              reminder.imagePath!.isNotEmpty
                          ? Image.file(
                              File(reminder.imagePath!),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 250,
                              errorBuilder: (_, __, ___) => Container(
                                height: 250,
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.alarm,
                                size: 80,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Reminder Details
                  // Card(
                  //   color: cardColor,
                  //   elevation: isDark ? 2 : 4,
                  //   margin: const EdgeInsets.symmetric(
                  //     horizontal: 0,
                  //     vertical: 8,
                  //   ),
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(16),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(20),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         Text(
                  //           reminder.title,
                  //           style: GoogleFonts.poppins(
                  //             fontSize: 22,
                  //             fontWeight: FontWeight.w600,
                  //             color: textColor,
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 20),

                  // Reminder Info Details
                  ..._buildReminderDetails(context, reminder, ref),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: Text(
                            ref.watch(currentTextProvider('editReminder')) ??
                                'Edit Reminder',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green[400],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () =>
                              context.go('/reminder/edit', extra: reminder),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
