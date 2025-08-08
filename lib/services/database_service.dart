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
        version: 6,
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
          wake_quality INTEGER,
          movements_json TEXT,
          created_at INTEGER NOT NULL,
          sleep_stages_json TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_profiles (
          id TEXT PRIMARY KEY,
          nickname TEXT,
          age_group TEXT,
          gender TEXT,
          occupation TEXT,
          target_sleep_hours REAL NOT NULL,
          target_bedtime TEXT NOT NULL,
          target_wake_time TEXT NOT NULL,
          weekday_bedtime TEXT,
          weekday_wake_time TEXT,
          weekend_bedtime TEXT,
          weekend_wake_time TEXT,
          sleep_concerns_json TEXT,
          caffeine_habit TEXT,
          alcohol_habit TEXT,
          exercise_habit TEXT,
          phone_usage_time TEXT,
          phone_usage_content_json TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          notification_settings_json TEXT,
          is_onboarding_completed INTEGER NOT NULL DEFAULT 0,
          sleep_literacy_score INTEGER,
          sleep_literacy_test_date INTEGER,
          sleep_literacy_test_duration_minutes INTEGER,
          sleep_literacy_category_scores_json TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sleep_records_start_time ON sleep_records(start_time);
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_sleep_records_created_at ON sleep_records(created_at);
      ''');

      // 日次集計データテーブル
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_sleep_aggregates (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          sleep_duration_minutes INTEGER,
          sleep_quality REAL,
          bedtime_hour INTEGER,
          bedtime_minute INTEGER,
          wake_time_hour INTEGER,
          wake_time_minute INTEGER,
          movement_count INTEGER,
          deep_sleep_percentage REAL,
          light_sleep_percentage REAL,
          rem_sleep_percentage REAL,
          awake_percentage REAL,
          day_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          UNIQUE(user_id, date)
        )
      ''');

      // 週次集計データテーブル
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weekly_sleep_aggregates (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          week_start_date TEXT NOT NULL,
          avg_sleep_duration REAL,
          avg_sleep_quality REAL,
          consistency_score REAL,
          weekday_avg_duration REAL,
          weekend_avg_duration REAL,
          social_jetlag_minutes INTEGER,
          created_at INTEGER NOT NULL,
          UNIQUE(user_id, week_start_date)
        )
      ''');

      // 集計データのインデックス
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_daily_aggregates_user_date ON daily_sleep_aggregates(user_id, date);
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_weekly_aggregates_user_week ON weekly_sleep_aggregates(user_id, week_start_date);
      ''');

    } catch (e) {
      print('Table creation failed: $e');
      rethrow;
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // バージョン1→2: 分析用テーブルを追加
    if (oldVersion < 2) {
      // 日次集計データテーブル
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_sleep_aggregates (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          date TEXT NOT NULL,
          sleep_duration_minutes INTEGER,
          sleep_quality REAL,
          bedtime_hour INTEGER,
          bedtime_minute INTEGER,
          wake_time_hour INTEGER,
          wake_time_minute INTEGER,
          movement_count INTEGER,
          deep_sleep_percentage REAL,
          light_sleep_percentage REAL,
          rem_sleep_percentage REAL,
          awake_percentage REAL,
          day_type TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          UNIQUE(user_id, date)
        )
      ''');

      // 週次集計データテーブル
      await db.execute('''
        CREATE TABLE IF NOT EXISTS weekly_sleep_aggregates (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          week_start_date TEXT NOT NULL,
          avg_sleep_duration REAL,
          avg_sleep_quality REAL,
          consistency_score REAL,
          weekday_avg_duration REAL,
          weekend_avg_duration REAL,
          social_jetlag_minutes INTEGER,
          created_at INTEGER NOT NULL,
          UNIQUE(user_id, week_start_date)
        )
      ''');

      // 集計データのインデックス
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_daily_aggregates_user_date ON daily_sleep_aggregates(user_id, date);
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_weekly_aggregates_user_week ON weekly_sleep_aggregates(user_id, week_start_date);
      ''');
    }
    
    // バージョン2→3: オンボーディング関連カラムを追加
    if (oldVersion < 3) {
      // user_profilesテーブルにオンボーディング関連カラムを追加
      await db.execute('ALTER TABLE user_profiles ADD COLUMN nickname TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN age_group TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN gender TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN occupation TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN weekday_bedtime TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN weekday_wake_time TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN weekend_bedtime TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN weekend_wake_time TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN sleep_concerns_json TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN caffeine_habit TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN alcohol_habit TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN exercise_habit TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN phone_usage_time TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN phone_usage_content_json TEXT');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN is_onboarding_completed INTEGER NOT NULL DEFAULT 0');
    }
    
    // バージョン3→4: 既存プロファイルのIDを標準化
    if (oldVersion < 4) {
      // タイムスタンプベースのIDを持つプロファイルがあれば、default_userに変更
      final profiles = await db.query('user_profiles');
      for (final profile in profiles) {
        final currentId = profile['id'] as String;
        // 数値のみのIDの場合（タイムスタンプ）、default_userに変更
        if (RegExp(r'^\d+$').hasMatch(currentId)) {
          await db.update(
            'user_profiles',
            {'id': 'default_user'},
            where: 'id = ?',
            whereArgs: [currentId],
          );
          print('Database: Updated profile ID from $currentId to default_user');
        }
      }
    }
    
    // バージョン4→5: 目覚めの質カラムを追加
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE sleep_records ADD COLUMN wake_quality INTEGER');
      print('Database: Added wake_quality column to sleep_records table');
    }
    
    // バージョン5→6: 睡眠リテラシーテスト関連カラムを追加
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE user_profiles ADD COLUMN sleep_literacy_score INTEGER');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN sleep_literacy_test_date INTEGER');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN sleep_literacy_test_duration_minutes INTEGER');
      await db.execute('ALTER TABLE user_profiles ADD COLUMN sleep_literacy_category_scores_json TEXT');
      print('Database: Added sleep literacy test columns to user_profiles table');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}