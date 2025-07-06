import 'package:sqflite/sqflite.dart';
import '../models/sleep_record_model.dart';
import '../models/user_profile_model.dart';
import '../../services/database_service.dart';

class LocalDataSource {
  final DatabaseService _databaseService;

  LocalDataSource({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  Future<void> insertSleepRecord(SleepRecordModel record) async {
    final db = await _databaseService.database;
    await db.insert(
      'sleep_records',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSleepRecord(SleepRecordModel record) async {
    final db = await _databaseService.database;
    await db.update(
      'sleep_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<SleepRecordModel?> getSleepRecordById(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return SleepRecordModel.fromMap(maps.first);
  }

  Future<SleepRecordModel?> getActiveSleepRecord() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_records',
      where: 'end_time IS NULL',
      orderBy: 'start_time DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return SleepRecordModel.fromMap(maps.first);
  }

  Future<List<SleepRecordModel>> getSleepRecords({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final db = await _databaseService.database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (from != null) {
      whereClause = 'start_time >= ?';
      whereArgs.add(from.millisecondsSinceEpoch);
    }

    if (to != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'start_time <= ?';
      whereArgs.add(to.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'sleep_records',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_time DESC',
      limit: limit,
    );

    return maps.map((map) => SleepRecordModel.fromMap(map)).toList();
  }

  Future<void> deleteSleepRecord(String id) async {
    final db = await _databaseService.database;
    await db.delete(
      'sleep_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertOrUpdateUserProfile(UserProfileModel profile) async {
    final db = await _databaseService.database;
    await db.insert(
      'user_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserProfileModel?> getUserProfile(String id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return UserProfileModel.fromMap(maps.first);
  }

  Future<UserProfileModel?> getDefaultUserProfile() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profiles',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return UserProfileModel.fromMap(maps.first);
  }
}