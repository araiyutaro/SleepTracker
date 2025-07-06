import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/domain/entities/sleep_session.dart';

void main() {
  group('SleepSession', () {
    test('should create a valid sleep session', () {
      final startTime = DateTime(2025, 7, 6, 22, 0);
      final endTime = DateTime(2025, 7, 7, 6, 0);
      
      final session = SleepSession(
        id: 'test-id',
        startTime: startTime,
        endTime: endTime,
        duration: Duration(hours: 8),
        qualityScore: 85.5,
        movements: [],
        createdAt: DateTime.now(),
      );

      expect(session.id, 'test-id');
      expect(session.startTime, startTime);
      expect(session.endTime, endTime);
      expect(session.duration, Duration(hours: 8));
      expect(session.qualityScore, 85.5);
      expect(session.movements, isEmpty);
    });

    test('should create sleep session without end time', () {
      final startTime = DateTime(2025, 7, 6, 22, 0);
      
      final session = SleepSession(
        id: 'test-id',
        startTime: startTime,
        movements: [],
        createdAt: DateTime.now(),
      );

      expect(session.id, 'test-id');
      expect(session.startTime, startTime);
      expect(session.endTime, isNull);
      expect(session.duration, isNull);
      expect(session.qualityScore, isNull);
    });

    test('should copy with new values', () {
      final startTime = DateTime(2025, 7, 6, 22, 0);
      final session = SleepSession(
        id: 'test-id',
        startTime: startTime,
        movements: [],
        createdAt: DateTime.now(),
      );

      final updatedSession = session.copyWith(
        endTime: DateTime(2025, 7, 7, 6, 0),
        duration: Duration(hours: 8),
        qualityScore: 90.0,
      );

      expect(updatedSession.id, session.id);
      expect(updatedSession.startTime, session.startTime);
      expect(updatedSession.endTime, DateTime(2025, 7, 7, 6, 0));
      expect(updatedSession.duration, Duration(hours: 8));
      expect(updatedSession.qualityScore, 90.0);
    });

    test('should create movement data', () {
      final timestamp = DateTime.now();
      final movement = MovementData(
        timestamp: timestamp,
        intensity: 1.8,
      );

      expect(movement.timestamp, timestamp);
      expect(movement.intensity, 1.8);
    });

    test('should create sleep stage data', () {
      final sleepStages = SleepStageData(
        deepSleepPercentage: 25.0,
        lightSleepPercentage: 50.0,
        remSleepPercentage: 20.0,
        awakePercentage: 5.0,
        movementCount: 45,
      );

      expect(sleepStages.deepSleepPercentage, 25.0);
      expect(sleepStages.lightSleepPercentage, 50.0);
      expect(sleepStages.remSleepPercentage, 20.0);
      expect(sleepStages.awakePercentage, 5.0);
      expect(sleepStages.movementCount, 45);
    });
  });
}