import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/domain/entities/sleep_session.dart';
import 'package:sleep/domain/repositories/sleep_repository.dart';
import 'package:sleep/domain/repositories/user_repository.dart';
import 'package:sleep/domain/usecases/end_sleep_tracking_usecase.dart';

import 'end_sleep_tracking_usecase_test.mocks.dart';

@GenerateMocks([SleepRepository, UserRepository])
void main() {
  late EndSleepTrackingUseCase usecase;
  late MockSleepRepository mockSleepRepository;
  late MockUserRepository mockUserRepository;

  setUp(() {
    mockSleepRepository = MockSleepRepository();
    mockUserRepository = MockUserRepository();
    usecase = EndSleepTrackingUseCase(mockSleepRepository, mockUserRepository);
  });

  group('EndSleepTrackingUseCase', () {
    test('should end sleep tracking successfully and add points', () async {
      final startTime = DateTime.now().subtract(Duration(hours: 8));
      final endTime = DateTime.now();
      final activeSession = SleepSession(
        id: 'test-id',
        startTime: startTime,
        movements: [],
        createdAt: startTime,
      );
      
      final endedSession = SleepSession(
        id: 'test-id',
        startTime: startTime,
        endTime: endTime,
        duration: Duration(hours: 8),
        qualityScore: 85.0,
        movements: [],
        createdAt: startTime,
      );

      when(mockSleepRepository.getActiveSession())
          .thenAnswer((_) async => activeSession);
      when(mockSleepRepository.endSession(any))
          .thenAnswer((_) async => endedSession);
      when(mockUserRepository.updatePoints(any))
          .thenAnswer((_) async {});

      final result = await usecase.execute();

      expect(result, endedSession);
      verify(mockSleepRepository.getActiveSession()).called(1);
      verify(mockSleepRepository.endSession(any)).called(1);
      verify(mockUserRepository.updatePoints(150)).called(1); // 8時間睡眠で100ポイント + 品質ボーナス50ポイント
    });

    test('should add bonus points for high quality sleep', () async {
      final startTime = DateTime.now().subtract(Duration(hours: 8));
      final endTime = DateTime.now();
      final activeSession = SleepSession(
        id: 'test-id',
        startTime: startTime,
        movements: [],
        createdAt: startTime,
      );
      
      final endedSession = SleepSession(
        id: 'test-id',
        startTime: startTime,
        endTime: endTime,
        duration: Duration(hours: 8),
        qualityScore: 95.0, // 高品質な睡眠
        movements: [],
        createdAt: startTime,
      );

      when(mockSleepRepository.getActiveSession())
          .thenAnswer((_) async => activeSession);
      when(mockSleepRepository.endSession(any))
          .thenAnswer((_) async => endedSession);
      when(mockUserRepository.updatePoints(any))
          .thenAnswer((_) async {});

      final result = await usecase.execute();

      expect(result, endedSession);
      verify(mockUserRepository.updatePoints(150)).called(1); // 基本ポイント + ボーナス
    });

    test('should throw exception when no active session exists', () async {
      when(mockSleepRepository.getActiveSession())
          .thenAnswer((_) async => null);

      expect(
        () async => await usecase.execute(),
        throwsException,
      );

      verify(mockSleepRepository.getActiveSession()).called(1);
      verifyNever(mockSleepRepository.endSession(any));
      verifyNever(mockUserRepository.updatePoints(any));
    });

    test('should throw exception when repository fails', () async {
      when(mockSleepRepository.getActiveSession())
          .thenThrow(Exception('Database error'));

      expect(
        () async => await usecase.execute(),
        throwsException,
      );

      verify(mockSleepRepository.getActiveSession()).called(1);
    });
  });
}