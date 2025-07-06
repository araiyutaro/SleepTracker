import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/domain/entities/user_profile.dart';

void main() {
  group('UserProfile', () {
    test('should create a valid user profile', () {
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

      expect(profile.id, 'user-123');
      expect(profile.targetSleepHours, 8.0);
      expect(profile.targetBedtime.hour, 22);
      expect(profile.targetBedtime.minute, 30);
      expect(profile.targetWakeTime.hour, 6);
      expect(profile.targetWakeTime.minute, 30);
      expect(profile.points, 1500);
      expect(profile.achievements, isEmpty);
    });

    test('should copy with new values', () {
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

      final updatedProfile = profile.copyWith(
        targetSleepHours: 7.5,
        points: 2000,
      );

      expect(updatedProfile.id, profile.id);
      expect(updatedProfile.targetSleepHours, 7.5);
      expect(updatedProfile.points, 2000);
      expect(updatedProfile.targetBedtime, profile.targetBedtime);
      expect(updatedProfile.targetWakeTime, profile.targetWakeTime);
    });

    test('should create achievement with correct properties', () {
      final unlockedTime = DateTime.now();
      final achievement = Achievement(
        id: 'first_sleep',
        name: '初めての記録',
        description: '初めて睡眠を記録',
        iconPath: 'assets/achievements/first_sleep.png',
        points: 50,
        unlockedAt: unlockedTime,
      );

      expect(achievement.id, 'first_sleep');
      expect(achievement.name, '初めての記録');
      expect(achievement.description, '初めて睡眠を記録');
      expect(achievement.iconPath, 'assets/achievements/first_sleep.png');
      expect(achievement.points, 50);
      expect(achievement.isUnlocked, true);
      expect(achievement.unlockedAt, unlockedTime);
    });
  });

  group('NotificationSettings', () {
    test('should create default notification settings', () {
      final settings = NotificationSettings();

      expect(settings.bedtimeReminderEnabled, true);
      expect(settings.bedtimeReminderMinutes, 30);
      expect(settings.wakeUpAlarmEnabled, false);
      expect(settings.sleepQualityNotificationEnabled, true);
      expect(settings.weeklyReportEnabled, true);
    });

    test('should create custom notification settings', () {
      final settings = NotificationSettings(
        bedtimeReminderEnabled: false,
        bedtimeReminderMinutes: 60,
        wakeUpAlarmEnabled: true,
        sleepQualityNotificationEnabled: false,
        weeklyReportEnabled: false,
      );

      expect(settings.bedtimeReminderEnabled, false);
      expect(settings.bedtimeReminderMinutes, 60);
      expect(settings.wakeUpAlarmEnabled, true);
      expect(settings.sleepQualityNotificationEnabled, false);
      expect(settings.weeklyReportEnabled, false);
    });

    test('should copy with new values', () {
      final settings = NotificationSettings();
      
      final updatedSettings = settings.copyWith(
        bedtimeReminderEnabled: false,
        wakeUpAlarmEnabled: true,
      );

      expect(updatedSettings.bedtimeReminderEnabled, false);
      expect(updatedSettings.wakeUpAlarmEnabled, true);
      expect(updatedSettings.bedtimeReminderMinutes, settings.bedtimeReminderMinutes);
      expect(updatedSettings.sleepQualityNotificationEnabled, settings.sleepQualityNotificationEnabled);
      expect(updatedSettings.weeklyReportEnabled, settings.weeklyReportEnabled);
    });
  });
}