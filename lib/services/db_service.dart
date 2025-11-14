import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder_model.dart';

class DBService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'reminders.db');
    return await openDatabase(
      path,
      version: 4, // increment version to ensure upgrade runs
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE reminders(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT,
            cause TEXT,
            symptoms TEXT,
            prevention TEXT,
            treatment TEXT,
            reminderTime INTEGER NOT NULL,
            repeat TEXT NOT NULL DEFAULT 'none',
            imagePath TEXT,
            synced INTEGER NOT NULL DEFAULT 0,
            enabled INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Get current columns
        var columns = await db.rawQuery('PRAGMA table_info(reminders)');

        // Add synced column if missing
        if (!columns.any((col) => col['name'] == 'synced')) {
          await db.execute(
            'ALTER TABLE reminders ADD COLUMN synced INTEGER DEFAULT 0',
          );
        }

        // Add enabled column if missing
        if (!columns.any((col) => col['name'] == 'enabled')) {
          await db.execute(
            'ALTER TABLE reminders ADD COLUMN enabled INTEGER DEFAULT 1',
          );
        }

        // Add disease-related columns if missing
        if (!columns.any((col) => col['name'] == 'cause')) {
          await db.execute('ALTER TABLE reminders ADD COLUMN cause TEXT');
        }
        if (!columns.any((col) => col['name'] == 'symptoms')) {
          await db.execute('ALTER TABLE reminders ADD COLUMN symptoms TEXT');
        }
        if (!columns.any((col) => col['name'] == 'prevention')) {
          await db.execute('ALTER TABLE reminders ADD COLUMN prevention TEXT');
        }
        if (!columns.any((col) => col['name'] == 'treatment')) {
          await db.execute('ALTER TABLE reminders ADD COLUMN treatment TEXT');
        }
      },
    );
  }

  static Future<void> insertReminder(ReminderModel reminder) async {
    final db = await database;
    await db.insert(
      'reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateReminder(ReminderModel reminder) async {
    final db = await database;
    await db.update(
      'reminders',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  static Future<void> deleteReminder(String id) async {
    final db = await database;
    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<ReminderModel>> getReminders() async {
    final db = await database;
    final data = await db.query('reminders');
    return data.map((e) => ReminderModel.fromMap(e)).toList();
  }
}
