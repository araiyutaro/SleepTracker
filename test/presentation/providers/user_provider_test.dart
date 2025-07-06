import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/domain/entities/user_profile.dart';
import 'package:sleep/domain/repositories/user_repository.dart';
import 'package:sleep/presentation/providers/user_provider.dart';
import 'package:sleep/services/notification_service.dart';

import 'user_provider_test.mocks.dart';

@GenerateMocks([UserRepository, NotificationService])
void main() {
  late UserProvider userProvider;
  late MockUserRepository mockUserRepository;
  late MockNotificationService mockNotificationService;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockUserRepository = MockUserRepository();
    mockNotificationService = MockNotificationService();
    userProvider = UserProvider(userRepository: mockUserRepository);
    // NotificationServiceのモックを注入（実際の実装では依存性注入が必要）
  });

  group('UserProvider', () {
    test('should load user profile on initialization', () async {
      final profile = UserProfile(
        id: 'user-123',
        targetSleepHours: 8.0,
        targetBedtime: TimeOfDay(hour: 22, minute: 30),
        targetWakeTime: TimeOfDay(hour: 6, minute: 30),
        points: 1500,
        achievements: [],
        notificationSettings: NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => profile);

      // プロバイダーを作成（自動的に初期化される）
      final provider = UserProvider(userRepository: mockUserRepository);
      
      // 初期化完了まで待機
      await Future.delayed(Duration(milliseconds: 100));

      expect(provider.userProfile, isNotNull);
      expect(provider.userProfile?.id, 'user-123');
      verify(mockUserRepository.getUserProfile()).called(1);
    });

    test('should update settings successfully', () async {
      final initialProfile = UserProfile(
        id: 'user-123',
        targetSleepHours: 8.0,
        targetBedtime: TimeOfDay(hour: 22, minute: 30),
        targetWakeTime: TimeOfDay(hour: 6, minute: 30),
        points: 1500,
        achievements: [],
        notificationSettings: NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => initialProfile);
      when(mockUserRepository.saveUserProfile(any))
          .thenAnswer((_) async {});

      final provider = UserProvider(userRepository: mockUserRepository);
      await Future.delayed(Duration(milliseconds: 100));

      await provider.updateSettings(
        targetSleepHours: 7.5,
        targetBedtime: TimeOfDay(hour: 23, minute: 0),
      );

      verify(mockUserRepository.saveUserProfile(any)).called(1);
      expect(provider.userProfile?.targetSleepHours, 7.5);
      expect(provider.userProfile?.targetBedtime.hour, 23);
    });

    test('should update notification settings successfully', () async {
      final initialProfile = UserProfile(
        id: 'user-123',
        targetSleepHours: 8.0,
        targetBedtime: TimeOfDay(hour: 22, minute: 30),
        targetWakeTime: TimeOfDay(hour: 6, minute: 30),
        points: 1500,
        achievements: [],
        notificationSettings: NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => initialProfile);
      when(mockUserRepository.saveUserProfile(any))
          .thenAnswer((_) async {});

      final provider = UserProvider(userRepository: mockUserRepository);
      await Future.delayed(Duration(milliseconds: 100));

      final newSettings = NotificationSettings(
        bedtimeReminderEnabled: false,
        wakeUpAlarmEnabled: true,
      );

      await provider.updateNotificationSettings(newSettings);

      verify(mockUserRepository.saveUserProfile(any)).called(1);
      expect(provider.userProfile?.notificationSettings.bedtimeReminderEnabled, false);
      expect(provider.userProfile?.notificationSettings.wakeUpAlarmEnabled, true);
    });

    test('should add points successfully', () async {
      final initialProfile = UserProfile(
        id: 'user-123',
        targetSleepHours: 8.0,
        targetBedtime: TimeOfDay(hour: 22, minute: 30),
        targetWakeTime: TimeOfDay(hour: 6, minute: 30),
        points: 1500,
        achievements: [],
        notificationSettings: NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedProfile = initialProfile.copyWith(points: 1600);

      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => initialProfile);
      when(mockUserRepository.updatePoints(100))
          .thenAnswer((_) async {});

      final provider = UserProvider(userRepository: mockUserRepository);
      await Future.delayed(Duration(milliseconds: 100));

      // 2回目の呼び出し用に更新されたプロファイルを設定
      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => updatedProfile);

      await provider.addPoints(100);

      verify(mockUserRepository.updatePoints(100)).called(1);
      verify(mockUserRepository.getUserProfile()).called(2); // 初期化 + addPoints後
    });

    test('should unlock achievement successfully', () async {
      final initialProfile = UserProfile(
        id: 'user-123',
        targetSleepHours: 8.0,
        targetBedtime: TimeOfDay(hour: 22, minute: 30),
        targetWakeTime: TimeOfDay(hour: 6, minute: 30),
        points: 1500,
        achievements: [],
        notificationSettings: NotificationSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => initialProfile);
      when(mockUserRepository.unlockAchievement('first_sleep'))
          .thenAnswer((_) async {});

      final provider = UserProvider(userRepository: mockUserRepository);
      await Future.delayed(Duration(milliseconds: 100));

      await provider.unlockAchievement('first_sleep');

      verify(mockUserRepository.unlockAchievement('first_sleep')).called(1);
      verify(mockUserRepository.getUserProfile()).called(2); // 初期化 + unlock後
    });

    test('should handle null user profile gracefully', () async {
      when(mockUserRepository.getUserProfile())
          .thenAnswer((_) async => null);

      final provider = UserProvider(userRepository: mockUserRepository);
      await Future.delayed(Duration(milliseconds: 100));

      expect(provider.userProfile, isNull);

      // 設定更新は何もしない
      await provider.updateSettings(targetSleepHours: 7.0);
      verifyNever(mockUserRepository.saveUserProfile(any));
    });
  });
}