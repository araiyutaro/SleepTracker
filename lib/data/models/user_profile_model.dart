import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  final String id;
  final String? nickname;
  final String? ageGroup;
  final String? gender;
  final String? occupation;
  final double targetSleepHours;
  final String targetBedtime;
  final String targetWakeTime;
  final String? weekdayBedtime;
  final String? weekdayWakeTime;
  final String? weekendBedtime;
  final String? weekendWakeTime;
  final String? sleepConcernsJson;
  final String? caffeineHabit;
  final String? alcoholHabit;
  final String? exerciseHabit;
  final String? phoneUsageTime;
  final String? phoneUsageContentJson;
  final int points;
  final String? achievementsJson;
  final int createdAtEpoch;
  final int updatedAtEpoch;
  final String? notificationSettingsJson;
  final int isOnboardingCompleted;

  UserProfileModel({
    required this.id,
    this.nickname,
    this.ageGroup,
    this.gender,
    this.occupation,
    required this.targetSleepHours,
    required this.targetBedtime,
    required this.targetWakeTime,
    this.weekdayBedtime,
    this.weekdayWakeTime,
    this.weekendBedtime,
    this.weekendWakeTime,
    this.sleepConcernsJson,
    this.caffeineHabit,
    this.alcoholHabit,
    this.exerciseHabit,
    this.phoneUsageTime,
    this.phoneUsageContentJson,
    required this.points,
    this.achievementsJson,
    required this.createdAtEpoch,
    required this.updatedAtEpoch,
    this.notificationSettingsJson,
    required this.isOnboardingCompleted,
  });

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      nickname: entity.nickname,
      ageGroup: entity.ageGroup,
      gender: entity.gender,
      occupation: entity.occupation,
      targetSleepHours: entity.targetSleepHours,
      targetBedtime: _timeOfDayToString(entity.targetBedtime),
      targetWakeTime: _timeOfDayToString(entity.targetWakeTime),
      weekdayBedtime: entity.weekdayBedtime != null ? _timeOfDayToString(entity.weekdayBedtime!) : null,
      weekdayWakeTime: entity.weekdayWakeTime != null ? _timeOfDayToString(entity.weekdayWakeTime!) : null,
      weekendBedtime: entity.weekendBedtime != null ? _timeOfDayToString(entity.weekendBedtime!) : null,
      weekendWakeTime: entity.weekendWakeTime != null ? _timeOfDayToString(entity.weekendWakeTime!) : null,
      sleepConcernsJson: entity.sleepConcerns.isEmpty ? null : entity.sleepConcerns.join(','),
      caffeineHabit: entity.caffeineHabit,
      alcoholHabit: entity.alcoholHabit,
      exerciseHabit: entity.exerciseHabit,
      phoneUsageTime: entity.phoneUsageTime,
      phoneUsageContentJson: entity.phoneUsageContent.isEmpty ? null : entity.phoneUsageContent.join(','),
      points: entity.points,
      achievementsJson: _achievementsToJson(entity.achievements),
      createdAtEpoch: entity.createdAt.millisecondsSinceEpoch,
      updatedAtEpoch: entity.updatedAt.millisecondsSinceEpoch,
      notificationSettingsJson: _notificationSettingsToJson(entity.notificationSettings),
      isOnboardingCompleted: entity.isOnboardingCompleted ? 1 : 0,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      nickname: nickname,
      ageGroup: ageGroup,
      gender: gender,
      occupation: occupation,
      targetSleepHours: targetSleepHours,
      targetBedtime: _stringToTimeOfDay(targetBedtime),
      targetWakeTime: _stringToTimeOfDay(targetWakeTime),
      weekdayBedtime: weekdayBedtime != null ? _stringToTimeOfDay(weekdayBedtime!) : null,
      weekdayWakeTime: weekdayWakeTime != null ? _stringToTimeOfDay(weekdayWakeTime!) : null,
      weekendBedtime: weekendBedtime != null ? _stringToTimeOfDay(weekendBedtime!) : null,
      weekendWakeTime: weekendWakeTime != null ? _stringToTimeOfDay(weekendWakeTime!) : null,
      sleepConcerns: sleepConcernsJson?.split(',') ?? [],
      caffeineHabit: caffeineHabit,
      alcoholHabit: alcoholHabit,
      exerciseHabit: exerciseHabit,
      phoneUsageTime: phoneUsageTime,
      phoneUsageContent: phoneUsageContentJson?.split(',') ?? [],
      points: points,
      achievements: _achievementsFromJson(achievementsJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtEpoch),
      notificationSettings: _notificationSettingsFromJson(notificationSettingsJson),
      isOnboardingCompleted: isOnboardingCompleted == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nickname': nickname,
      'age_group': ageGroup,
      'gender': gender,
      'occupation': occupation,
      'target_sleep_hours': targetSleepHours,
      'target_bedtime': targetBedtime,
      'target_wake_time': targetWakeTime,
      'weekday_bedtime': weekdayBedtime,
      'weekday_wake_time': weekdayWakeTime,
      'weekend_bedtime': weekendBedtime,
      'weekend_wake_time': weekendWakeTime,
      'sleep_concerns_json': sleepConcernsJson,
      'caffeine_habit': caffeineHabit,
      'alcohol_habit': alcoholHabit,
      'exercise_habit': exerciseHabit,
      'phone_usage_time': phoneUsageTime,
      'phone_usage_content_json': phoneUsageContentJson,
      'points': points,
      'achievements_json': achievementsJson,
      'created_at': createdAtEpoch,
      'updated_at': updatedAtEpoch,
      'notification_settings_json': notificationSettingsJson,
      'is_onboarding_completed': isOnboardingCompleted,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      nickname: map['nickname'] as String?,
      ageGroup: map['age_group'] as String?,
      gender: map['gender'] as String?,
      occupation: map['occupation'] as String?,
      targetSleepHours: map['target_sleep_hours'] as double,
      targetBedtime: map['target_bedtime'] as String,
      targetWakeTime: map['target_wake_time'] as String,
      weekdayBedtime: map['weekday_bedtime'] as String?,
      weekdayWakeTime: map['weekday_wake_time'] as String?,
      weekendBedtime: map['weekend_bedtime'] as String?,
      weekendWakeTime: map['weekend_wake_time'] as String?,
      sleepConcernsJson: map['sleep_concerns_json'] as String?,
      caffeineHabit: map['caffeine_habit'] as String?,
      alcoholHabit: map['alcohol_habit'] as String?,
      exerciseHabit: map['exercise_habit'] as String?,
      phoneUsageTime: map['phone_usage_time'] as String?,
      phoneUsageContentJson: map['phone_usage_content_json'] as String?,
      points: map['points'] as int,
      achievementsJson: map['achievements_json'] as String?,
      createdAtEpoch: map['created_at'] as int,
      updatedAtEpoch: map['updated_at'] as int,
      notificationSettingsJson: map['notification_settings_json'] as String?,
      isOnboardingCompleted: map['is_onboarding_completed'] as int? ?? 0,
    );
  }

  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static TimeOfDay _stringToTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  static String? _achievementsToJson(List<Achievement> achievements) {
    if (achievements.isEmpty) return null;
    return achievements
        .map((a) =>
            '${a.id}|${a.name}|${a.description}|${a.iconPath}|${a.unlockedAt?.millisecondsSinceEpoch ?? 0}|${a.points}')
        .join(';');
  }

  static List<Achievement> _achievementsFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    return json.split(';').map((item) {
      final parts = item.split('|');
      return Achievement(
        id: parts[0],
        name: parts[1],
        description: parts[2],
        iconPath: parts[3],
        unlockedAt: parts[4] != '0'
            ? DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4]))
            : null,
        points: int.parse(parts[5]),
      );
    }).toList();
  }

  static String? _notificationSettingsToJson(NotificationSettings settings) {
    return '${settings.bedtimeReminderEnabled ? 1 : 0}:'
           '${settings.bedtimeReminderMinutes}:'
           '${settings.wakeUpAlarmEnabled ? 1 : 0}:'
           '${settings.sleepQualityNotificationEnabled ? 1 : 0}:'
           '${settings.weeklyReportEnabled ? 1 : 0}';
  }

  static NotificationSettings _notificationSettingsFromJson(String? json) {
    if (json == null || json.isEmpty) return NotificationSettings();
    final parts = json.split(':');
    if (parts.length != 5) return NotificationSettings();
    
    return NotificationSettings(
      bedtimeReminderEnabled: parts[0] == '1',
      bedtimeReminderMinutes: int.parse(parts[1]),
      wakeUpAlarmEnabled: parts[2] == '1',
      sleepQualityNotificationEnabled: parts[3] == '1',
      weeklyReportEnabled: parts[4] == '1',
    );
  }
}