import 'package:uuid/uuid.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../datasources/local_data_source.dart';
import '../models/sleep_record_model.dart';

class SleepRepositoryImpl implements SleepRepository {
  final LocalDataSource _localDataSource;
  final _uuid = const Uuid();

  SleepRepositoryImpl({
    required LocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<SleepSession> startSession(SleepSession session) async {
    final model = SleepRecordModel.fromEntity(session);
    await _localDataSource.insertSleepRecord(model);
    return session;
  }

  @override
  Future<SleepSession> endSession(String sessionId) async {
    try {
      final record = await _localDataSource.getSleepRecordById(sessionId);
      if (record == null) {
        // アクティブセッションから再取得を試行
        final activeRecord = await _localDataSource.getActiveSleepRecord();
        if (activeRecord == null || activeRecord.id != sessionId) {
          throw Exception('Sleep session not found: $sessionId');
        }
        // アクティブセッションが見つかった場合、それを使用
        final endTime = DateTime.now();
        final duration = endTime.difference(
          DateTime.fromMillisecondsSinceEpoch(activeRecord.startTimeEpoch),
        );

        final updatedRecord = SleepRecordModel(
          id: activeRecord.id,
          startTimeEpoch: activeRecord.startTimeEpoch,
          endTimeEpoch: endTime.millisecondsSinceEpoch,
          durationMinutes: duration.inMinutes,
          qualityScore: _calculateQualityScore(duration),
          movementsJson: activeRecord.movementsJson,
          createdAtEpoch: activeRecord.createdAtEpoch,
          sleepStagesJson: activeRecord.sleepStagesJson,
        );

        await _localDataSource.updateSleepRecord(updatedRecord);
        return updatedRecord.toEntity();
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(
        DateTime.fromMillisecondsSinceEpoch(record.startTimeEpoch),
      );

      final updatedRecord = SleepRecordModel(
        id: record.id,
        startTimeEpoch: record.startTimeEpoch,
        endTimeEpoch: endTime.millisecondsSinceEpoch,
        durationMinutes: duration.inMinutes,
        qualityScore: _calculateQualityScore(duration),
        movementsJson: record.movementsJson,
        createdAtEpoch: record.createdAtEpoch,
        sleepStagesJson: record.sleepStagesJson,
      );

      await _localDataSource.updateSleepRecord(updatedRecord);
      return updatedRecord.toEntity();
    } catch (e) {
      throw Exception('Failed to end sleep session: $e');
    }
  }

  @override
  Future<SleepSession?> getActiveSession() async {
    final record = await _localDataSource.getActiveSleepRecord();
    return record?.toEntity();
  }

  @override
  Future<SleepSession?> getSessionById(String id) async {
    final record = await _localDataSource.getSleepRecordById(id);
    return record?.toEntity();
  }

  @override
  Future<List<SleepSession>> getSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final records = await _localDataSource.getSleepRecords(
      from: from,
      to: to,
      limit: limit,
    );
    return records.map((record) => record.toEntity()).toList();
  }

  @override
  Future<void> deleteSession(String id) async {
    await _localDataSource.deleteSleepRecord(id);
  }

  @override
  Future<void> updateSession(SleepSession session) async {
    final model = SleepRecordModel.fromEntity(session);
    await _localDataSource.updateSleepRecord(model);
  }

  double _calculateQualityScore(Duration duration) {
    final hours = duration.inHours;
    if (hours >= 7 && hours <= 9) {
      return 90.0;
    } else if (hours >= 6 && hours <= 10) {
      return 75.0;
    } else if (hours >= 5 && hours <= 11) {
      return 60.0;
    } else {
      return 40.0;
    }
  }
}