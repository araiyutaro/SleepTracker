import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sleep/data/repositories/user_repository_impl.dart';
import 'package:sleep/data/datasources/local_data_source.dart';
import 'package:sleep/data/models/user_profile_model.dart';
import 'package:sleep/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';

import 'user_repository_impl_test.mocks.dart';

@GenerateMocks([LocalDataSource])
void main() {
  late UserRepositoryImpl repository;
  late MockLocalDataSource mockLocalDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    repository = UserRepositoryImpl(localDataSource: mockLocalDataSource);
  });

  group('UserRepositoryImpl', () {
    group('getUserProfile', () {
      test('should return user profile when found', () async {
        // Arrange
        final userProfileModel = UserProfileModel(
          id: 'test-id',
          nickname: 'Test User',
          ageGroup: '20代',
          gender: '男性',
          occupation: 'エンジニア',
          targetSleepHours: 8.0,
          targetBedtime: '23:00',
          targetWakeTime: '07:00',
          sleepConcernsJson: 'なかなか眠れない,夜中に目が覚める',
          caffeineHabit: '1日2-3杯',
          alcoholHabit: 'ほとんど飲まない',
          exerciseHabit: '週3-4回',
          phoneUsageTime: '1-2時間',
          phoneUsageContentJson: 'SNS,動画',
          createdAtEpoch: DateTime.now().millisecondsSinceEpoch,
          updatedAtEpoch: DateTime.now().millisecondsSinceEpoch,
          isOnboardingCompleted: 1,
        );

        when(mockLocalDataSource.getUserProfile('default_user'))
            .thenAnswer((_) async => userProfileModel);

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-id'));
        expect(result.nickname, equals('Test User'));
        expect(result.isOnboardingCompleted, isTrue);
        verify(mockLocalDataSource.getUserProfile('default_user')).called(1);
      });

      test('should return null when profile not found', () async {
        // Arrange
        when(mockLocalDataSource.getUserProfile('default_user'))
            .thenAnswer((_) async => null);

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result, isNull);
        verify(mockLocalDataSource.getUserProfile('default_user')).called(1);
      });

      test('should migrate profile from default_user to UUID when found', () async {
        // Arrange
        final userProfileModel = UserProfileModel(
          id: 'default_user',
          nickname: 'Old User',
          ageGroup: '30代',
          gender: '女性',
          occupation: 'デザイナー',
          targetSleepHours: 7.5,
          targetBedtime: '22:30',
          targetWakeTime: '06:30',
          sleepConcernsJson: '',
          caffeineHabit: '1日1杯',
          alcoholHabit: 'たまに飲む',
          exerciseHabit: '週1-2回',
          phoneUsageTime: '30分-1時間',
          phoneUsageContentJson: 'SNS',
          createdAtEpoch: DateTime.now().millisecondsSinceEpoch,
          updatedAtEpoch: DateTime.now().millisecondsSinceEpoch,
          isOnboardingCompleted: 1,
        );

        when(mockLocalDataSource.getUserProfile('default_user'))
            .thenAnswer((_) async => userProfileModel);

        // Act
        final result = await repository.getUserProfile();

        // Assert
        expect(result, isNotNull);
        expect(result!.id, isNot('default_user')); // UUIDに変更されている
        expect(result.nickname, equals('Old User'));
        
        // 新しいUUIDで保存が呼ばれているか確認
        verify(mockLocalDataSource.insertOrUpdateUserProfile(any)).called(1);
      });
    });

    group('saveUserProfile', () {
      test('should save user profile to local data source', () async {
        // Arrange
        final userProfile = UserProfile(
          id: 'test-uuid',
          nickname: 'Test User',
          ageGroup: '20代',
          gender: '男性',
          occupation: 'エンジニア',
          targetSleepHours: 8.0,
          targetBedtime: const TimeOfDay(hour: 23, minute: 0),
          targetWakeTime: const TimeOfDay(hour: 7, minute: 0),
          sleepConcerns: ['なかなか眠れない', '夜中に目が覚める'],
          caffeineHabit: '1日2-3杯',
          alcoholHabit: 'ほとんど飲まない',
          exerciseHabit: '週3-4回',
          phoneUsageTime: '1-2時間',
          phoneUsageContent: ['SNS', '動画'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          notificationSettings: NotificationSettings(),
          isOnboardingCompleted: true,
        );

        // Act
        await repository.saveUserProfile(userProfile);

        // Assert - capture and verify the method was called
        final capturedModel = verify(mockLocalDataSource.insertOrUpdateUserProfile(captureAny))
            .captured.first as UserProfileModel;
        expect(capturedModel.id, equals('test-uuid'));
        expect(capturedModel.nickname, equals('Test User'));
        expect(capturedModel.isOnboardingCompleted, equals(1));
      });

      test('should handle errors from local data source', () async {
        // Arrange
        final userProfile = UserProfile(
          id: 'test-uuid',
          nickname: 'Test User',
          targetSleepHours: 8.0,
          targetBedtime: const TimeOfDay(hour: 23, minute: 0),
          targetWakeTime: const TimeOfDay(hour: 7, minute: 0),
          sleepConcerns: [],
          phoneUsageContent: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          notificationSettings: NotificationSettings(),
          isOnboardingCompleted: true,
        );

        when(mockLocalDataSource.insertOrUpdateUserProfile(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.saveUserProfile(userProfile),
          throwsException,
        );
      });

      test('should convert UserProfile entity to UserProfileModel correctly', () async {
        // Arrange
        final now = DateTime.now();
        final userProfile = UserProfile(
          id: 'test-uuid',
          nickname: 'Detailed User',
          ageGroup: '40代',
          gender: '女性',
          occupation: 'マネージャー',
          targetSleepHours: 7.5,
          targetBedtime: const TimeOfDay(hour: 22, minute: 30),
          targetWakeTime: const TimeOfDay(hour: 6, minute: 0),
          weekdayBedtime: const TimeOfDay(hour: 23, minute: 0),
          weekdayWakeTime: const TimeOfDay(hour: 6, minute: 30),
          weekendBedtime: const TimeOfDay(hour: 23, minute: 30),
          weekendWakeTime: const TimeOfDay(hour: 7, minute: 30),
          sleepConcerns: ['眠りが浅い', 'ストレス'],
          caffeineHabit: '1日4-5杯',
          alcoholHabit: '毎日飲む',
          exerciseHabit: 'ほとんどしない',
          phoneUsageTime: '3時間以上',
          phoneUsageContent: ['SNS', '動画', 'ゲーム'],
          createdAt: now,
          updatedAt: now,
          isOnboardingCompleted: true,
          sleepLiteracyScore: 9,
          sleepLiteracyTestDate: now,
          sleepLiteracyTestDurationMinutes: 20,
          notificationSettings: NotificationSettings(),
        );

        // Act
        await repository.saveUserProfile(userProfile);

        // Assert
        final capturedModel = verify(mockLocalDataSource.insertOrUpdateUserProfile(captureAny))
            .captured.first as UserProfileModel;
            
        expect(capturedModel.id, equals('test-uuid'));
        expect(capturedModel.nickname, equals('Detailed User'));
        expect(capturedModel.ageGroup, equals('40代'));
        expect(capturedModel.gender, equals('女性'));
        expect(capturedModel.occupation, equals('マネージャー'));
        expect(capturedModel.targetSleepHours, equals(7.5));
        expect(capturedModel.targetBedtime, equals('22:30'));
        expect(capturedModel.targetWakeTime, equals('06:00'));
        expect(capturedModel.sleepConcernsJson, contains('眠りが浅い'));
        expect(capturedModel.sleepConcernsJson, contains('ストレス'));
        expect(capturedModel.phoneUsageContentJson, contains('SNS'));
        expect(capturedModel.phoneUsageContentJson, contains('動画'));
        expect(capturedModel.phoneUsageContentJson, contains('ゲーム'));
        expect(capturedModel.isOnboardingCompleted, equals(1));
      });
    });
  });
}