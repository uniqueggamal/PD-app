import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/reminder_model.dart';
import '../../models/scan_history_model.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/text_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/localization_provider.dart';

class AddEditReminderScreen extends ConsumerStatefulWidget {
  final ReminderModel? reminder;
  final Map<String, dynamic>? extraData;
  const AddEditReminderScreen({this.reminder, this.extraData, super.key});

  @override
  ConsumerState<AddEditReminderScreen> createState() =>
      _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends ConsumerState<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _causeController;
  late TextEditingController _symptomsController;
  late TextEditingController _preventionController;
  late TextEditingController _treatmentController;

  String _repeatType = 'none';
  Set<String> _selectedDays = {};
  DateTime _selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
  File? _selectedImage;

  @override
  void initState() {
    super.initState();

    final r = widget.reminder;

    _titleController = TextEditingController(text: r?.title ?? '');
    _descriptionController = TextEditingController(text: r?.description ?? '');
    _causeController = TextEditingController(text: r?.cause ?? '');
    _symptomsController = TextEditingController(text: r?.symptoms ?? '');
    _preventionController = TextEditingController(text: r?.prevention ?? '');
    _treatmentController = TextEditingController(text: r?.treatment ?? '');

    // Image
    if (r?.imagePath != null && r!.imagePath!.isNotEmpty) {
      _selectedImage = File(r.imagePath!);
    }

    // Repeat setup
    final repeat = r?.repeat ?? 'none';
    if (repeat == 'none') {
      _repeatType = 'none';
    } else if (repeat == 'daily') {
      _repeatType = 'daily';
      _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    } else if (repeat.isNotEmpty) {
      _repeatType = 'custom';
      _selectedDays = repeat.split(',').toSet();
    }

    // Time setup – reminderTime is DateTime in the model
    if (r != null && r.reminderTime != null) {
      _selectedDateTime = r.reminderTime!;
    } else {
      // New reminder: now + 1 minute
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    }

    // Pre-fill from extraData (camera → reminder flow or scan detail)
    if (widget.extraData != null) {
      final extra = widget.extraData!;
      final scan = extra['scan'] as ScanHistoryModel?;
      final cureInfo = extra['cureInfo'] as Map<String, dynamic>?;

      if (scan != null) {
        // Pre-fill from scan data
        _titleController.text = scan.diseaseName;
        if (scan.imagePath != null && scan.imagePath!.isNotEmpty) {
          _selectedImage = File(scan.imagePath!);
        }
        // Pre-fill description with notes if available
        if (scan.notes != null && scan.notes!.isNotEmpty) {
          _descriptionController.text = scan.notes!;
        }

        // Pre-fill cure information into respective fields
        if (cureInfo != null) {
          _causeController.text = cureInfo['Cause']?.toString() ?? '';
          _symptomsController.text = cureInfo['Symptoms']?.toString() ?? '';
          _preventionController.text = cureInfo['Prevention']?.toString() ?? '';
          _treatmentController.text = cureInfo['Treatment']?.toString() ?? '';
          // Use Description as additional description if no notes
          if (_descriptionController.text.isEmpty) {
            _descriptionController.text =
                cureInfo['Description']?.toString() ?? '';
          }
        }
      } else {
        // Fallback to direct extra data (camera flow)
        _titleController.text =
            extra['title']?.toString() ?? _titleController.text;
        _descriptionController.text =
            extra['description']?.toString() ?? _descriptionController.text;
        _causeController.text =
            extra['cause']?.toString() ?? _causeController.text;
        _symptomsController.text =
            extra['symptoms']?.toString() ?? _symptomsController.text;
        _preventionController.text =
            extra['prevention']?.toString() ?? _preventionController.text;
        _treatmentController.text =
            extra['treatment']?.toString() ?? _treatmentController.text;

        if (extra['imagePath'] != null &&
            extra['imagePath'].toString().isNotEmpty) {
          _selectedImage = File(extra['imagePath'].toString());
        }

        // Handle reminderTime from extra (usually int from camera)
        final extraTime = extra['reminderTime'];
        if (extraTime != null) {
          if (extraTime is int) {
            _selectedDateTime = DateTime.fromMillisecondsSinceEpoch(extraTime);
          } else if (extraTime is DateTime) {
            _selectedDateTime = extraTime; // rare case
          }
        }
      }
    }

    // Initialize date formatting (only once per app start is better, but ok here)
    initializeDateFormatting();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _causeController.dispose();
    _symptomsController.dispose();
    _preventionController.dispose();
    _treatmentController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked == null) return;

    var newDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );

    // Ensure future time
    if (newDateTime.isBefore(now)) {
      newDateTime = newDateTime.add(const Duration(days: 1));
    }

    setState(() => _selectedDateTime = newDateTime);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  String? _validateRepeat() {
    if (_repeatType == 'custom' && _selectedDays.isEmpty) {
      return ref.read(currentTextProvider('pleaseSelectDays')) ??
          'Please select at least one day';
    }
    return null;
  }

  void _saveReminder() {
    if (!_formKey.currentState!.validate()) return;

    final repeatError = _validateRepeat();
    if (repeatError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(repeatError)));
      return;
    }

    if (_selectedDateTime.isBefore(DateTime.now())) {
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(currentTextProvider('timeAdjusted')) ??
                'Reminder time adjusted to 1 minute from now',
          ),
        ),
      );
    }

    String repeatStr;
    if (_repeatType == 'none') {
      repeatStr = 'none';
      _selectedDays.clear();
    } else if (_repeatType == 'daily') {
      repeatStr = 'daily';
      _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    } else {
      // Sort days for consistent order (mon → sun)
      final orderedDays = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      final sortedDays = _selectedDays.toList()
        ..sort(
          (a, b) => orderedDays.indexOf(a).compareTo(orderedDays.indexOf(b)),
        );
      repeatStr = sortedDays.join(','); // ← join here → becomes String
    }

    final newReminder = ReminderModel(
      id: widget.reminder?.id ?? Random().nextInt(1000000000).toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      cause: _causeController.text.trim(),
      symptoms: _symptomsController.text.trim(),
      prevention: _preventionController.text.trim(),
      treatment: _treatmentController.text.trim(),
      reminderTime: _selectedDateTime,
      repeat: repeatStr,
      imagePath: _selectedImage?.path,
    );

    final notifier = ref.read(reminderProvider.notifier);
    if (widget.reminder == null) {
      notifier.addReminder(newReminder);
    } else {
      notifier.updateReminder(newReminder);
    }

    context.go('/reminders');
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final currentLocale = ref.watch(localeProvider);

    final List<Map<String, String>> days = [
      {'key': 'mon', 'label': ref.read(currentTextProvider('monday')) ?? 'Mon'},
      {
        'key': 'tue',
        'label': ref.read(currentTextProvider('tuesday')) ?? 'Tue',
      },
      {
        'key': 'wed',
        'label': ref.read(currentTextProvider('wednesday')) ?? 'Wed',
      },
      {
        'key': 'thu',
        'label': ref.read(currentTextProvider('thursday')) ?? 'Thu',
      },
      {'key': 'fri', 'label': ref.read(currentTextProvider('friday')) ?? 'Fri'},
      {
        'key': 'sat',
        'label': ref.read(currentTextProvider('saturday')) ?? 'Sat',
      },
      {'key': 'sun', 'label': ref.read(currentTextProvider('sunday')) ?? 'Sun'},
    ];

    final textColor = isDarkMode ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.reminder == null
              ? ref.read(currentTextProvider('addReminder')) ?? 'Add Reminder'
              : ref.read(currentTextProvider('editReminder')) ??
                    'Edit Reminder',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reminders'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(_titleController, 'title', textColor),
                const SizedBox(height: 12),
                _buildTextField(
                  _descriptionController,
                  'description',
                  textColor,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildTextField(_causeController, 'cause', textColor),
                const SizedBox(height: 12),
                _buildTextField(_symptomsController, 'symptoms', textColor),
                const SizedBox(height: 12),
                _buildTextField(_preventionController, 'prevention', textColor),
                const SizedBox(height: 12),
                _buildTextField(_treatmentController, 'treatment', textColor),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _repeatType,
                  items: [
                    DropdownMenuItem(
                      value: 'none',
                      child: Text(
                        ref.read(currentTextProvider('norepeat')) ??
                            'No Repeat',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(
                        ref.read(currentTextProvider('daily')) ?? 'Daily',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text(
                        ref.read(currentTextProvider('custom')) ?? 'Custom',
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _repeatType = val!;
                      if (_repeatType != 'custom') _selectedDays.clear();
                      if (_repeatType == 'daily') {
                        _selectedDays = {
                          'mon',
                          'tue',
                          'wed',
                          'thu',
                          'fri',
                          'sat',
                          'sun',
                        };
                      }
                    });
                  },
                  decoration: InputDecoration(
                    labelText:
                        ref.read(currentTextProvider('repeat')) ?? 'Repeat',
                  ),
                ),

                if (_repeatType == 'custom') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: days.map((dayMap) {
                      final key = dayMap['key']!;
                      final label = dayMap['label']!;
                      final selected = _selectedDays.contains(key);

                      return FilterChip(
                        label: Text(label, style: TextStyle(color: textColor)),
                        selected: selected,
                        onSelected: (val) {
                          setState(() {
                            if (val)
                              _selectedDays.add(key);
                            else
                              _selectedDays.remove(key);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 16),

                Center(
                  child: ElevatedButton(
                    onPressed: _pickTime,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade500,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      DateFormat(
                        'HH:mm',
                        currentLocale.languageCode,
                      ).format(_selectedDateTime),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(
                      ref.read(currentTextProvider('pickImage')) ??
                          'Pick Image',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                if (_selectedImage != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _saveReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          widget.reminder == null
                              ? ref.read(currentTextProvider('addReminder')) ??
                                    'Add Reminder'
                              : ref.read(currentTextProvider('saveReminder')) ??
                                    'Save',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.reminder == null) {
                            context.go('/reminders');
                          } else {
                            // Optional: Add confirmation dialog before delete
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Reminder?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(reminderProvider.notifier)
                                          .deleteReminder(widget.reminder!.id);
                                      Navigator.pop(ctx);
                                      context.go('/reminders');
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          widget.reminder == null
                              ? ref.read(currentTextProvider('cancel')) ??
                                    'Cancel'
                              : ref.read(currentTextProvider('delete')) ??
                                    'Delete',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String key,
    Color textColor, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: ref.read(currentTextProvider(key)),
      ),
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      validator: (v) =>
          (v == null || v.trim().isEmpty) && key == 'title' ? 'Required' : null,
    );
  }
}
