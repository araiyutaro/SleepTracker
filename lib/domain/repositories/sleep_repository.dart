import '../entities/sleep_session.dart';

abstract class SleepRepository {
  Future<SleepSession> startSession(SleepSession session);
  Future<SleepSession> endSession(String sessionId);
  Future<SleepSession?> getActiveSession();
  Future<SleepSession?> getSessionById(String id);
  Future<List<SleepSession>> getSessions({
    DateTime? from,
    DateTime? to,
    int? limit,
  });
  Future<void> deleteSession(String id);
  Future<void> updateSession(SleepSession session);
}