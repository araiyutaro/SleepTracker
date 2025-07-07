import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/services/widget_service.dart';
import 'package:sleep/domain/repositories/sleep_repository.dart';
import 'package:sleep/domain/entities/sleep_session.dart';

@GenerateMocks([SleepRepository])
import 'widget_service_test.mocks.dart';

void main() {
  group('WidgetService', () {
    late WidgetService widgetService;
    late MockSleepRepository mockSleepRepository;

    setUp(() {
      mockSleepRepository = MockSleepRepository();
      widgetService = WidgetService(sleepRepository: mockSleepRepository);
    });

    test('generateWidgetData returns empty data when no sessions exist', () async {
      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => []);

      final result = await widgetService.generateWidgetData();

      expect(result.lastSleepDate, '記録なし');
      expect(result.lastSleepDuration, '--');
      expect(result.sleepQuality, '--');
      expect(result.weeklyAverage, '--');
      expect(result.totalSessions, 0);
    });

    test('generateWidgetData returns correct data for single session', () async {
      final session = SleepSession(
        id: '1',
        startTime: DateTime(2023, 12, 15, 22, 0),
        endTime: DateTime(2023, 12, 16, 7, 30),
        qualityScore: 85.0,
      );

      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => [session]);

      final result = await widgetService.generateWidgetData();

      expect(result.lastSleepDate, '12/15');
      expect(result.lastSleepDuration, '9h30m');
      expect(result.sleepQuality, '85%');
      expect(result.totalSessions, 1);
    });

    test('generateWidgetData calculates weekly average correctly', () async {
      final now = DateTime.now();
      final sessions = [
        SleepSession(
          id: '1',
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now.subtract(const Duration(days: 1)).add(const Duration(hours: 8)),
          qualityScore: 80.0,
        ),
        SleepSession(
          id: '2',
          startTime: now.subtract(const Duration(days: 3)),
          endTime: now.subtract(const Duration(days: 3)).add(const Duration(hours: 7)),
          qualityScore: 75.0,
        ),
        SleepSession(
          id: '3',
          startTime: now.subtract(const Duration(days: 5)),
          endTime: now.subtract(const Duration(days: 5)).add(const Duration(hours: 9)),
          qualityScore: 90.0,
        ),
      ];

      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => sessions);

      final result = await widgetService.generateWidgetData();

      expect(result.weeklyAverage, '8.0h');
      expect(result.totalSessions, 3);
    });

    test('generateWidgetData handles sessions without duration', () async {
      final session = SleepSession(
        id: '1',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        qualityScore: 85.0,
      );

      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => [session]);

      final result = await widgetService.generateWidgetData();

      expect(result.lastSleepDuration, '--');
      expect(result.sleepQuality, '85%');
    });

    test('generateWidgetData handles sessions without quality score', () async {
      final session = SleepSession(
        id: '1',
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().subtract(const Duration(days: 1)).add(const Duration(hours: 8)),
      );

      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => [session]);

      final result = await widgetService.generateWidgetData();

      expect(result.lastSleepDuration, '8h0m');
      expect(result.sleepQuality, '--');
    });

    test('generateWidgetData handles repository errors gracefully', () async {
      when(mockSleepRepository.getSessions(limit: 20))
          .thenThrow(Exception('Database error'));

      final result = await widgetService.generateWidgetData();

      expect(result.lastSleepDate, 'エラー');
      expect(result.lastSleepDuration, '--');
      expect(result.sleepQuality, '--');
      expect(result.weeklyAverage, '--');
      expect(result.totalSessions, 0);
    });

    test('isWidgetSupported returns true', () async {
      final result = await widgetService.isWidgetSupported();
      expect(result, true);
    });

    test('getWidgetLayout returns valid JSON structure', () {
      final layout = widgetService.getWidgetLayout();
      expect(layout.contains('"title": "睡眠トラッカー"'), true);
      expect(layout.contains('"layout": "compact"'), true);
      expect(layout.contains('"elements"'), true);
    });

    test('updateWidget completes without error', () async {
      when(mockSleepRepository.getSessions(limit: 20))
          .thenAnswer((_) async => []);

      expect(() => widgetService.updateWidget(), returnsNormally);
    });

    test('configureWidget completes without error', () async {
      expect(() => widgetService.configureWidget(
        showQuality: true,
        showWeeklyAverage: false,
        showTotalSessions: true,
      ), returnsNormally);
    });
  });

  group('WidgetData', () {
    test('toJson converts object to map correctly', () {
      final data = WidgetData(
        lastSleepDate: '12/15',
        lastSleepDuration: '8h30m',
        sleepQuality: '85%',
        weeklyAverage: '7.5h',
        totalSessions: 10,
      );

      final json = data.toJson();

      expect(json['lastSleepDate'], '12/15');
      expect(json['lastSleepDuration'], '8h30m');
      expect(json['sleepQuality'], '85%');
      expect(json['weeklyAverage'], '7.5h');
      expect(json['totalSessions'], 10);
    });

    test('fromJson creates object from map correctly', () {
      final json = {
        'lastSleepDate': '12/15',
        'lastSleepDuration': '8h30m',
        'sleepQuality': '85%',
        'weeklyAverage': '7.5h',
        'totalSessions': 10,
      };

      final data = WidgetData.fromJson(json);

      expect(data.lastSleepDate, '12/15');
      expect(data.lastSleepDuration, '8h30m');
      expect(data.sleepQuality, '85%');
      expect(data.weeklyAverage, '7.5h');
      expect(data.totalSessions, 10);
    });

    test('fromJson handles missing fields with default values', () {
      final json = <String, dynamic>{};

      final data = WidgetData.fromJson(json);

      expect(data.lastSleepDate, '');
      expect(data.lastSleepDuration, '');
      expect(data.sleepQuality, '');
      expect(data.weeklyAverage, '');
      expect(data.totalSessions, 0);
    });
  });
}