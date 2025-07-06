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
    final record = await _localDataSource.getSleepRecordById(sessionId);
    if (record == null) {
      throw Exception('Sleep session not found');
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
    );

    await _localDataSource.updateSleepRecord(updatedRecord);
    return updatedRecord.toEntity();
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