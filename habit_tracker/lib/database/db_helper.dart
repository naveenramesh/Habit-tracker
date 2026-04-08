import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/habit.dart';
import '../models/habit_log.dart';

class DBHelper {
  static final DBHelper instance = DBHelper._internal();
  static Database? _db;
  DBHelper._internal();

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'habit_tracker.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE habits (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT DEFAULT '✅',
        color INTEGER DEFAULT 4284955135,
        category TEXT DEFAULT 'General',
        is_break_habit INTEGER DEFAULT 0,
        frequency_type TEXT DEFAULT 'daily',
        specific_days TEXT DEFAULT '[]',
        target_value REAL DEFAULT 1.0,
        unit TEXT DEFAULT '',
        start_date TEXT,
        is_archived INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE habit_logs (
        id TEXT PRIMARY KEY,
        habit_id TEXT NOT NULL,
        date TEXT NOT NULL,
        value REAL DEFAULT 0.0,
        is_completed INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        is_skipped INTEGER DEFAULT 0,
        skip_reason TEXT DEFAULT '',
        created_at TEXT,
        FOREIGN KEY (habit_id) REFERENCES habits (id)
      )
    ''');
  }

  // ── Habits ────────────────────────────────────────────────
  Future<void> insertHabit(Habit habit) async {
    final db = await database;
    await db.insert('habits', habit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Habit>> getAllHabits({bool includeArchived = false}) async {
    final db = await database;
    final rows = await db.query(
      'habits',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'created_at ASC',
    );
    return rows.map(Habit.fromMap).toList();
  }

  Future<void> updateHabit(Habit habit) async {
    final db = await database;
    await db.update('habits', habit.toMap(),
        where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.delete('habits', where: 'id = ?', whereArgs: [id]);
    await db.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
  }

  // ── Logs ──────────────────────────────────────────────────
  Future<void> insertLog(HabitLog log) async {
    final db = await database;
    await db.insert('habit_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<HabitLog?> getLogForDate(String habitId, String date) async {
    final db = await database;
    final rows = await db.query('habit_logs',
        where: 'habit_id = ? AND date = ?',
        whereArgs: [habitId, date],
        limit: 1);
    return rows.isEmpty ? null : HabitLog.fromMap(rows.first);
  }

  Future<List<HabitLog>> getLogsForHabit(String habitId) async {
    final db = await database;
    final rows = await db.query('habit_logs',
        where: 'habit_id = ?',
        whereArgs: [habitId],
        orderBy: 'date DESC');
    return rows.map(HabitLog.fromMap).toList();
  }

  Future<List<HabitLog>> getLogsInRange(
      String habitId, String start, String end) async {
    final db = await database;
    final rows = await db.query('habit_logs',
        where: 'habit_id = ? AND date >= ? AND date <= ?',
        whereArgs: [habitId, start, end],
        orderBy: 'date ASC');
    return rows.map(HabitLog.fromMap).toList();
  }

  Future<void> deleteLog(String logId) async {
    final db = await database;
    await db.delete('habit_logs', where: 'id = ?', whereArgs: [logId]);
  }

  // ── Stats helpers ─────────────────────────────────────────
  Future<int> currentStreak(String habitId, Habit habit) async {
    final logs = await getLogsForHabit(habitId);
    final completed = {
      for (final l in logs)
        if (l.isCompleted) l.date: true
    };

    int streak = 0;
    DateTime day = DateTime.now();

    while (true) {
      final key = _fmt(day);
      if (habit.isScheduledForDay(day)) {
        if (completed.containsKey(key)) {
          streak++;
        } else {
          // Allow today to still be pending
          if (day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day) {
            day = day.subtract(const Duration(days: 1));
            continue;
          }
          break;
        }
      }
      day = day.subtract(const Duration(days: 1));
      if (day.isBefore(DateTime.parse(habit.startDate))) break;
    }
    return streak;
  }

  Future<int> longestStreak(String habitId, Habit habit) async {
    final logs = await getLogsForHabit(habitId);
    final completed = {
      for (final l in logs)
        if (l.isCompleted) l.date: true
    };

    int longest = 0;
    int current = 0;
    DateTime start = DateTime.parse(habit.startDate);
    DateTime now = DateTime.now();

    for (DateTime d = start;
        !d.isAfter(now);
        d = d.add(const Duration(days: 1))) {
      if (!habit.isScheduledForDay(d)) continue;
      if (completed.containsKey(_fmt(d))) {
        current++;
        if (current > longest) longest = current;
      } else {
        if (_fmt(d) == _fmt(now)) continue; // today still pending
        current = 0;
      }
    }
    return longest;
  }

  Future<double> completionRate(
      String habitId, Habit habit, int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final logs = await getLogsInRange(habitId, _fmt(start), _fmt(end));
    final completed = {
      for (final l in logs)
        if (l.isCompleted) l.date: true
    };

    int scheduled = 0;
    int done = 0;
    for (DateTime d = start;
        !d.isAfter(end);
        d = d.add(const Duration(days: 1))) {
      if (!habit.isScheduledForDay(d)) continue;
      scheduled++;
      if (completed.containsKey(_fmt(d))) done++;
    }
    return scheduled == 0 ? 0.0 : done / scheduled;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Export / Import ───────────────────────────────────────
  Future<Map<String, dynamic>> exportAll() async {
    final habits = await getAllHabits(includeArchived: true);
    final db = await database;
    final logs = await db.query('habit_logs', orderBy: 'date ASC');
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'habits': habits.map((h) => h.toMap()).toList(),
      'logs': logs.toList(),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('habit_logs');
      await txn.delete('habits');
      for (final h in (data['habits'] as List)) {
        await txn.insert('habits', Map<String, dynamic>.from(h as Map),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final l in (data['logs'] as List)) {
        await txn.insert('habit_logs', Map<String, dynamic>.from(l as Map),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}
