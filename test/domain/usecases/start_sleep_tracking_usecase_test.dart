import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/domain/entities/sleep_session.dart';
import 'package:sleep/domain/repositories/sleep_repository.dart';
import 'package:sleep/domain/usecases/start_sleep_tracking_usecase.dart';

import 'start_sleep_tracking_usecase_test.mocks.dart';

@GenerateMocks([SleepRepository])
void main() {
  late StartSleepTrackingUseCase usecase;
  late MockSleepRepository mockRepository;

  setUp(() {
    mockRepository = MockSleepRepository();
    usecase = StartSleepTrackingUseCase(mockRepository);
  });

  group('StartSleepTrackingUseCase', () {
    test('should start sleep tracking successfully', () async {
      final startTime = DateTime.now();
      final expectedSession = SleepSession(
        id: 'test-id',
        startTime: startTime,
        movements: [],
        createdAt: startTime,
      );

      when(mockRepository.getActiveSession())
          .thenAnswer((_) async => null);
      when(mockRepository.startSession(any))
          .thenAnswer((_) async => expectedSession);

      final result = await usecase.execute();

      expect(result, expectedSession);
      verify(mockRepository.getActiveSession()).called(1);
      verify(mockRepository.startSession(any)).called(1);
    });

    test('should throw exception when active session exists', () async {
      final activeSession = SleepSession(
        id: 'active-id',
        startTime: DateTime.now(),
      );

      when(mockRepository.getActiveSession())
          .thenAnswer((_) async => activeSession);

      expect(
        () async => await usecase.execute(),
        throwsException,
      );

      verify(mockRepository.getActiveSession()).called(1);
      verifyNever(mockRepository.startSession(any));
    });

    test('should throw exception when repository fails', () async {
      when(mockRepository.getActiveSession())
          .thenThrow(Exception('Database error'));

      expect(
        () async => await usecase.execute(),
        throwsException,
      );

      verify(mockRepository.getActiveSession()).called(1);
    });
  });
}