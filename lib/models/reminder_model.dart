class ReminderModel {
  String id;
  String title;
  String? description;
  DateTime reminderTime;
  String repeat; // none, daily, weekly
  String? imagePath;
  bool synced;
  bool enabled;

  // Disease-related fields
  String? cause;
  String? symptoms;
  String? prevention;
  String? treatment;

  ReminderModel({
    required this.id,
    required this.title,
    this.description,
    required this.reminderTime,
    this.repeat = 'noRepeat',
    this.imagePath,
    this.synced = false,
    this.enabled = true,
    this.cause,
    this.symptoms,
    this.prevention,
    this.treatment,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'reminderTime': reminderTime.millisecondsSinceEpoch,
      'repeat': repeat,
      'imagePath': imagePath,
      'synced': synced ? 1 : 0,
      'enabled': enabled ? 1 : 0,
      'cause': cause,
      'symptoms': symptoms,
      'prevention': prevention,
      'treatment': treatment,
    };
  }

  factory ReminderModel.fromMap(Map<String, dynamic> map) {
    return ReminderModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      reminderTime: DateTime.fromMillisecondsSinceEpoch(map['reminderTime']),
      repeat: map['repeat'] ?? 'none',
      imagePath: map['imagePath'],
      synced: (map['synced'] as int?) == 1,
      enabled: (map['enabled'] as int?) != 0,
      cause: map['cause'],
      symptoms: map['symptoms'],
      prevention: map['prevention'],
      treatment: map['treatment'],
    );
  }

  ReminderModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? reminderTime,
    String? repeat,
    String? imagePath,
    bool? synced,
    bool? enabled,
    String? cause,
    String? symptoms,
    String? prevention,
    String? treatment,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      repeat: repeat ?? this.repeat,
      imagePath: imagePath ?? this.imagePath,
      synced: synced ?? this.synced,
      enabled: enabled ?? this.enabled,
      cause: cause ?? this.cause,
      symptoms: symptoms ?? this.symptoms,
      prevention: prevention ?? this.prevention,
      treatment: treatment ?? this.treatment,
    );
  }

  /// ✅ Determine if reminder is active
  bool isActive() {
    final now = DateTime.now();
    if (repeat == 'none' && reminderTime.isBefore(now)) {
      return false;
    }
    return enabled;
  }
}
