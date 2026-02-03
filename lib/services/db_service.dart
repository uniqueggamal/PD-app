import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/reminder_model.dart';
import '../models/scan_history_model.dart';

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
      version: 5, // bumped from 4 to 5 for scan_history table
      onCreate: (db, version) async {
        // 1. Create Reminders Table
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

        // 2. Create Scan History Table (REQUIRED for fresh installs)
        // This was missing, which would cause a crash on first run.
        await db.execute('''
          CREATE TABLE scan_history (
            id           TEXT PRIMARY KEY,
            image_path   TEXT NOT NULL,
            disease_key  TEXT,
            disease_name TEXT NOT NULL,
            confidence   REAL NOT NULL,
            plant_type   TEXT,
            notes        TEXT,
            is_treated   INTEGER NOT NULL DEFAULT 0,
            timestamp    INTEGER NOT NULL
          )
        ''');

        // Index for fast sorting by most recent scans
        await db.execute(
          'CREATE INDEX idx_scan_timestamp ON scan_history(timestamp DESC)',
        );
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

        // ── Upgrade: scan_history table (added in version 5) ──
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE scan_history (
              id           TEXT PRIMARY KEY,
              image_path   TEXT NOT NULL,
              disease_key  TEXT,
              disease_name TEXT NOT NULL,
              confidence   REAL NOT NULL,
              plant_type   TEXT,
              notes        TEXT,
              is_treated   INTEGER NOT NULL DEFAULT 0,
              timestamp    INTEGER NOT NULL
            )
          ''');

          // Index for fast sorting by most recent scans
          await db.execute(
            'CREATE INDEX idx_scan_timestamp ON scan_history(timestamp DESC)',
          );
        }
      },
    );
  }

  // ──────────────── Reminder Methods (unchanged) ────────────────

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

  // ──────────────── Scan History Methods ────────────────

  static Future<void> insertScan(ScanHistoryModel scan) async {
    final db = await database;
    await db.insert(
      'scan_history',
      scan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ScanHistoryModel>> getRecentScans({int limit = 50}) async {
    final db = await database;
    final data = await db.query(
      'scan_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return data.map((e) => ScanHistoryModel.fromMap(e)).toList();
  }

  static Future<List<ScanHistoryModel>> getScansByDiseaseKey(
    String diseaseKey,
  ) async {
    final db = await database;
    final data = await db.query(
      'scan_history',
      where: 'disease_key = ?',
      whereArgs: [diseaseKey],
      orderBy: 'timestamp DESC',
    );
    return data.map((e) => ScanHistoryModel.fromMap(e)).toList();
  }

  static Future<void> deleteScan(String id) async {
    final db = await database;
    // NOTE: This deletes the record from DB.
    // Consider adding File(imagePath).delete() here to clear storage if needed.
    await db.delete('scan_history', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> deleteAllScans() async {
    final db = await database;
    await db.delete('scan_history');
  }
}
