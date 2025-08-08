import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/data/repositories/sleep_repository_impl.dart';
import 'package:sleep/data/datasources/local_data_source.dart';
import 'package:sleep/data/models/sleep_record_model.dart';
import 'package:sleep/domain/entities/sleep_session.dart';

import 'sleep_repository_impl_test.mocks.dart';

@GenerateMocks([LocalDataSource])
void main() {
  late SleepRepositoryImpl repository;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    repository = SleepRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('SleepRepositoryImpl', () {
    group('startSession', () {
      test('should save sleep session to local data source', () async {
        // Arrange
        final session = SleepSession(
          id: 'test-id',
          startTime: DateTime(2024, 1, 1, 22, 0),
        );

        // Act
        final result = await repository.startSession(session);

        // Assert
        verify(mockLocalDataSource.insertSleepRecord(any)).called(1);
        expect(result, equals(session));
      });

      test('should handle errors from local data source', () async {
        // Arrange
        final session = SleepSession(
          id: 'test-id',
          startTime: DateTime(2024, 1, 1, 22, 0),
        );
        when(mockLocalDataSource.insertSleepRecord(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.startSession(session),
          throwsException,
        );
      });
    });

    group('endSession', () {
      test('should update sleep session with end time and duration', () async {
        // Arrange
        const sessionId = 'test-id';
        final startTime = DateTime(2024, 1, 1, 22, 0);
        final sleepRecord = SleepRecordModel(
          id: sessionId,
          startTimeEpoch: startTime.millisecondsSinceEpoch,
          endTimeEpoch: null,
          durationMinutes: null,
          qualityScore: null,
          movementsJson: '',
          createdAtEpoch: startTime.millisecondsSinceEpoch,
          sleepStagesJson: null,
        );

        when(mockLocalDataSource.getSleepRecordById(sessionId))
            .thenAnswer((_) async => sleepRecord);

        // Act
        final result = await repository.endSession(sessionId);

        // Assert
        verify(mockLocalDataSource.updateSleepRecord(any)).called(1);
        expect(result.id, equals(sessionId));
        expect(result.endTime, isNotNull);
        expect(result.duration, isNotNull);
        expect(result.qualityScore, isNotNull);
      });

      test('should handle case when session not found but active session exists', () async {
        // Arrange
        const sessionId = 'test-id';
        final startTime = DateTime(2024, 1, 1, 22, 0);
        final activeRecord = SleepRecordModel(
          id: sessionId,
          startTimeEpoch: startTime.millisecondsSinceEpoch,
          endTimeEpoch: null,
          durationMinutes: null,
          qualityScore: null,
          movementsJson: '',
          createdAtEpoch: startTime.millisecondsSinceEpoch,
          sleepStagesJson: null,
        );

        when(mockLocalDataSource.getSleepRecordById(sessionId))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource.getActiveSleepRecord())
            .thenAnswer((_) async => activeRecord);

        // Act
        final result = await repository.endSession(sessionId);

        // Assert
        verify(mockLocalDataSource.updateSleepRecord(any)).called(1);
        expect(result.id, equals(sessionId));
        expect(result.endTime, isNotNull);
      });

      test('should throw exception when session not found', () async {
        // Arrange
        const sessionId = 'non-existent-id';

        when(mockLocalDataSource.getSleepRecordById(sessionId))
            .thenAnswer((_) async => null);
        when(mockLocalDataSource.getActiveSleepRecord())
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.endSession(sessionId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getActiveSession', () {
      test('should return active session when exists', () async {
        // Arrange
        final sleepRecord = SleepRecordModel(
          id: 'active-id',
          startTimeEpoch: DateTime.now().millisecondsSinceEpoch,
          endTimeEpoch: null,
          durationMinutes: null,
          qualityScore: null,
          movementsJson: '',
          createdAtEpoch: DateTime.now().millisecondsSinceEpoch,
          sleepStagesJson: null,
        );

        when(mockLocalDataSource.getActiveSleepRecord())
            .thenAnswer((_) async => sleepRecord);

        // Act
        final result = await repository.getActiveSession();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('active-id'));
        expect(result.isActive, isTrue);
      });

      test('should return null when no active session', () async {
        // Arrange
        when(mockLocalDataSource.getActiveSleepRecord())
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getActiveSession();

        // Assert
        expect(result, isNull);
      });
    });

    group('getSessionById', () {
      test('should return session when found', () async {
        // Arrange
        const sessionId = 'test-id';
        final sleepRecord = SleepRecordModel(
          id: sessionId,
          startTimeEpoch: DateTime.now().millisecondsSinceEpoch,
          endTimeEpoch: DateTime.now().millisecondsSinceEpoch,
          durationMinutes: 480,
          qualityScore: 85.0,
          movementsJson: '',
          createdAtEpoch: DateTime.now().millisecondsSinceEpoch,
          sleepStagesJson: null,
        );

        when(mockLocalDataSource.getSleepRecordById(sessionId))
            .thenAnswer((_) async => sleepRecord);

        // Act
        final result = await repository.getSessionById(sessionId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(sessionId));
      });

      test('should return null when session not found', () async {
        // Arrange
        const sessionId = 'non-existent-id';

        when(mockLocalDataSource.getSleepRecordById(sessionId))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getSessionById(sessionId);

        // Assert
        expect(result, isNull);
      });
    });

    group('getSessions', () {
      test('should return list of sessions', () async {
        // Arrange
        final sleepRecords = [
          SleepRecordModel(
            id: 'id1',
            startTimeEpoch: DateTime(2024, 1, 1).millisecondsSinceEpoch,
            endTimeEpoch: DateTime(2024, 1, 2).millisecondsSinceEpoch,
            durationMinutes: 480,
            qualityScore: 85.0,
            movementsJson: '',
            createdAtEpoch: DateTime(2024, 1, 1).millisecondsSinceEpoch,
            sleepStagesJson: null,
          ),
          SleepRecordModel(
            id: 'id2',
            startTimeEpoch: DateTime(2024, 1, 2).millisecondsSinceEpoch,
            endTimeEpoch: DateTime(2024, 1, 3).millisecondsSinceEpoch,
            durationMinutes: 420,
            qualityScore: 78.0,
            movementsJson: '',
            createdAtEpoch: DateTime(2024, 1, 2).millisecondsSinceEpoch,
            sleepStagesJson: null,
          ),
        ];

        when(mockLocalDataSource.getSleepRecords(
          from: anyNamed('from'),
          to: anyNamed('to'),
          limit: anyNamed('limit'),
        )).thenAnswer((_) async => sleepRecords);

        // Act
        final result = await repository.getSessions();

        // Assert
        expect(result, hasLength(2));
        expect(result.first.id, equals('id1'));
        expect(result.last.id, equals('id2'));
      });

      test('should pass parameters to local data source', () async {
        // Arrange
        final from = DateTime(2024, 1, 1);
        final to = DateTime(2024, 1, 31);
        const limit = 10;

        when(mockLocalDataSource.getSleepRecords(
          from: from,
          to: to,
          limit: limit,
        )).thenAnswer((_) async => []);

        // Act
        await repository.getSessions(from: from, to: to, limit: limit);

        // Assert
        verify(mockLocalDataSource.getSleepRecords(
          from: from,
          to: to,
          limit: limit,
        )).called(1);
      });
    });

    group('deleteSession', () {
      test('should delete session from local data source', () async {
        // Arrange
        const sessionId = 'test-id';

        // Act
        await repository.deleteSession(sessionId);

        // Assert
        verify(mockLocalDataSource.deleteSleepRecord(sessionId)).called(1);
      });
    });

    group('updateSession', () {
      test('should update session in local data source', () async {
        // Arrange
        final session = SleepSession(
          id: 'test-id',
          startTime: DateTime(2024, 1, 1, 22, 0),
          endTime: DateTime(2024, 1, 2, 6, 0),
          qualityScore: 85.0,
        );

        // Act
        await repository.updateSession(session);

        // Assert
        verify(mockLocalDataSource.updateSleepRecord(any)).called(1);
      });
    });
  });
}