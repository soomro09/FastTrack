import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/fasting_log.dart';
import '../../models/weight_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fasting_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE fasting_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        targetDurationHours INTEGER NOT NULL,
        isCompleted INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weight REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // --- Fasting Log Methods ---

  Future<int> insertFastingLog(FastingLog log) async {
    final db = await instance.database;
    return await db.insert('fasting_logs', log.toMap());
  }

  Future<List<FastingLog>> getFastingLogs() async {
    final db = await instance.database;
    final result = await db.query('fasting_logs', orderBy: 'endTime DESC');
    return result.map((json) => FastingLog.fromMap(json)).toList();
  }

  Future<int> deleteFastingLog(int id) async {
    final db = await instance.database;
    return await db.delete('fasting_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllFastingLogs() async {
    final db = await instance.database;
    return await db.delete('fasting_logs');
  }

  // --- Weight Log Methods ---

  Future<int> insertWeightLog(WeightLog log) async {
    final db = await instance.database;
    return await db.insert('weight_logs', log.toMap());
  }

  Future<List<WeightLog>> getWeightLogs() async {
    final db = await instance.database;
    final result = await db.query('weight_logs', orderBy: 'date ASC');
    return result.map((json) => WeightLog.fromMap(json)).toList();
  }

  Future<int> deleteWeightLog(int id) async {
    final db = await instance.database;
    return await db.delete('weight_logs', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearAllWeightLogs() async {
    final db = await instance.database;
    return await db.delete('weight_logs');
  }
}
