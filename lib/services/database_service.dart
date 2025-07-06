import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'sleep_tracker.db');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: (db) async {
          // データベース接続時の設定
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      print('Database initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sleep_records (
          id TEXT PRIMARY KEY,
          start_time INTEGER NOT NULL,
          end_time INTEGER,
          duration_minutes INTEGER,
          quality_score REAL,
          movements_json TEXT,
          created_at INTEGER NOT NULL,
          sleep_stages_json TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          id TEXT PRIMARY KEY,
          target_sleep_hours REAL NOT NULL,
          target_bedtime TEXT NOT NULL,
          target_wake_time TEXT NOT NULL,
          points INTEGER NOT NULL DEFAULT 0,
          achievements_json TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          notification_settings_json TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sleep_records_start_time ON sleep_records(start_time);
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sleep_records_created_at ON sleep_records(created_at);
      ''');
    } catch (e) {
      print('Table creation failed: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 将来のバージョンアップ用
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}