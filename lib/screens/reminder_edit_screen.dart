import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/reminder_model.dart';
import '../providers/reminder_provider.dart';
import '../providers/text_provider.dart';
import '../providers/settings_provider.dart';

class AddEditReminderScreen extends ConsumerStatefulWidget {
  final ReminderModel? reminder;
  const AddEditReminderScreen({this.reminder, super.key});

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
  DateTime? _selectedDateTime;
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
    _selectedImage = r?.imagePath != null ? File(r!.imagePath!) : null;

    // Repeat setup
    final repeat = r?.repeat ?? 'none';
    if (repeat == 'none') {
      _repeatType = 'none';
    } else if (repeat == 'daily') {
      _repeatType = 'daily';
      _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    } else {
      _repeatType = 'custom';
      _selectedDays = repeat.split(',').toSet();
    }

    // Time setup
    if (r != null && r.reminderTime != null) {
      // Edit mode → keep existing time
      _selectedDateTime = r.reminderTime;
    } else {
      // Add mode → current time + 1 minute
      _selectedDateTime = DateTime.now().add(const Duration(minutes: 1));
    }

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
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (pickedTime == null) return;

    var selected = DateTime(
      now.year,
      now.month,
      now.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Ensure time is in the future
    if (selected.isBefore(now))
      selected = selected.add(const Duration(days: 1));

    setState(() => _selectedDateTime = selected);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null)
      setState(() => _selectedImage = File(pickedFile.path));
  }

  String? _validateRepeat() {
    if (_repeatType == 'custom' && _selectedDays.isEmpty) {
      return ref.read(currentTextProvider('pleaseSelectDays')) ??
          'Please select at least one day';
    }
    return null;
  }

  void _saveReminder() {
    // Form validation
    if (!_formKey.currentState!.validate()) return;

    // Repeat validation
    final repeatError = _validateRepeat();
    if (repeatError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(repeatError)));
      return;
    }

    // Datetime validation
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(currentTextProvider('pleaseSelectDateTime')) ??
                'Please select a reminder time',
          ),
        ),
      );
      return;
    }

    // Determine repeat string
    String repeat;
    if (_repeatType == 'none') {
      repeat = 'none';
      _selectedDays.clear();
    } else if (_repeatType == 'daily') {
      repeat = 'daily';
      _selectedDays = {'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'};
    } else {
      repeat = _selectedDays.join(',');
    }

    final newReminder = ReminderModel(
      id: widget.reminder?.id ?? Random().nextInt(1000000).toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      cause: _causeController.text,
      symptoms: _symptomsController.text,
      prevention: _preventionController.text,
      treatment: _treatmentController.text,
      reminderTime: _selectedDateTime!,
      repeat: repeat,
      imagePath: _selectedImage?.path,
    );

    final notifier = ref.read(reminderProvider.notifier);
    if (widget.reminder == null) {
      notifier.addReminder(newReminder);
    } else {
      notifier.updateReminder(newReminder);
    }

    Navigator.pop(context);
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
              ? ref.read(currentTextProvider('addReminder'))
              : ref.read(currentTextProvider('editReminder')),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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

                // Repeat Dropdown
                DropdownButtonFormField<String>(
                  value: _repeatType,
                  items: [
                    DropdownMenuItem(
                      value: 'none',
                      child: Text(ref.read(currentTextProvider('norepeat'))),
                    ),
                    DropdownMenuItem(
                      value: 'daily',
                      child: Text(ref.read(currentTextProvider('daily'))),
                    ),
                    DropdownMenuItem(
                      value: 'custom',
                      child: Text(ref.read(currentTextProvider('custom'))),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _repeatType = val!;
                      if (_repeatType != 'custom') _selectedDays.clear();
                      if (_repeatType == 'daily')
                        _selectedDays = {
                          'mon',
                          'tue',
                          'wed',
                          'thu',
                          'fri',
                          'sat',
                          'sun',
                        };
                    });
                  },
                  decoration: InputDecoration(
                    labelText: ref.read(currentTextProvider('repeat')),
                  ),
                ),

                if (_repeatType == 'custom') ...[
                  const SizedBox(height: 8),
                  Wrap(
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
                      _selectedDateTime == null
                          ? ref.read(currentTextProvider('selectDateTime'))
                          : DateFormat(
                              'HH:mm',
                              currentLocale.languageCode,
                            ).format(_selectedDateTime!),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(ref.read(currentTextProvider('pickImage'))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade800,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                if (_selectedImage != null && _selectedImage!.existsSync())
                  Center(child: Image.file(_selectedImage!, height: 150)),

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
                              ? ref.read(currentTextProvider('addReminder'))
                              : ref.read(currentTextProvider('saveReminder')),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (widget.reminder == null)
                            Navigator.pop(context);
                          else {
                            final notifier = ref.read(
                              reminderProvider.notifier,
                            );
                            notifier.deleteReminder(widget.reminder!.id);
                            Navigator.pop(context);
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
                              ? ref.read(currentTextProvider('cancel'))
                              : ref.read(currentTextProvider('delete')),
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
          (v == null || v.isEmpty) && key == 'title' ? 'Required' : null,
    );
  }
}
