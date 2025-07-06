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
    
    try {
      await db.transaction((txn) async {
        // 更新を試行
        final affectedRows = await txn.update(
          'sleep_records',
          record.toMap(),
          where: 'id = ?',
          whereArgs: [record.id],
        );
        
        // 更新されなかった場合、レコードが存在しないか、挿入が必要
        if (affectedRows == 0) {
          // 存在確認
          final existingRecords = await txn.query(
            'sleep_records',
            where: 'id = ?',
            whereArgs: [record.id],
          );
          
          if (existingRecords.isEmpty) {
            // レコードが存在しない場合は挿入
            await txn.insert(
              'sleep_records',
              record.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else {
            // レコードは存在するが更新できない場合
            throw Exception('Failed to update existing sleep record: ${record.id}');
          }
        }
      });
    } catch (e) {
      // トランザクションエラーの場合、シンプルな更新/挿入にフォールバック
      print('Transaction failed, trying fallback: $e');
      
      final affectedRows = await db.update(
        'sleep_records',
        record.toMap(),
        where: 'id = ?',
        whereArgs: [record.id],
      );
      
      if (affectedRows == 0) {
        // 更新できない場合は挿入
        await db.insert(
          'sleep_records',
          record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
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
      where: 'end_time IS NULL OR end_time = 0',
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