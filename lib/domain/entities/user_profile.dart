import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UserProfile {
  final String id;
  final String? nickname;
  final String? ageGroup;
  final String? gender;
  final String? occupation;
  final double targetSleepHours;
  final TimeOfDay targetBedtime;
  final TimeOfDay targetWakeTime;
  final TimeOfDay? weekdayBedtime;
  final TimeOfDay? weekdayWakeTime;
  final TimeOfDay? weekendBedtime;
  final TimeOfDay? weekendWakeTime;
  final List<String> sleepConcerns;
  final String? caffeineHabit;
  final String? alcoholHabit;
  final String? exerciseHabit;
  final String? phoneUsageTime;
  final List<String> phoneUsageContent;
  final int points;
  final List<Achievement> achievements;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NotificationSettings notificationSettings;
  final bool isOnboardingCompleted;

  UserProfile({
    String? id,
    this.nickname,
    this.ageGroup,
    this.gender,
    this.occupation,
    this.targetSleepHours = 8.0,
    TimeOfDay? targetBedtime,
    TimeOfDay? targetWakeTime,
    this.weekdayBedtime,
    this.weekdayWakeTime,
    this.weekendBedtime,
    this.weekendWakeTime,
    List<String>? sleepConcerns,
    this.caffeineHabit,
    this.alcoholHabit,
    this.exerciseHabit,
    this.phoneUsageTime,
    List<String>? phoneUsageContent,
    this.points = 0,
    List<Achievement>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotificationSettings? notificationSettings,
    this.isOnboardingCompleted = false,
  })  : id = id ?? const Uuid().v4(),
        targetBedtime = targetBedtime ?? const TimeOfDay(hour: 23, minute: 0),
        targetWakeTime = targetWakeTime ?? const TimeOfDay(hour: 7, minute: 0),
        sleepConcerns = sleepConcerns ?? [],
        phoneUsageContent = phoneUsageContent ?? [],
        achievements = achievements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        notificationSettings = notificationSettings ?? NotificationSettings();

  UserProfile copyWith({
    String? id,
    String? nickname,
    String? ageGroup,
    String? gender,
    String? occupation,
    double? targetSleepHours,
    TimeOfDay? targetBedtime,
    TimeOfDay? targetWakeTime,
    TimeOfDay? weekdayBedtime,
    TimeOfDay? weekdayWakeTime,
    TimeOfDay? weekendBedtime,
    TimeOfDay? weekendWakeTime,
    List<String>? sleepConcerns,
    String? caffeineHabit,
    String? alcoholHabit,
    String? exerciseHabit,
    String? phoneUsageTime,
    List<String>? phoneUsageContent,
    int? points,
    List<Achievement>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
    NotificationSettings? notificationSettings,
    bool? isOnboardingCompleted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      ageGroup: ageGroup ?? this.ageGroup,
      gender: gender ?? this.gender,
      occupation: occupation ?? this.occupation,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      targetBedtime: targetBedtime ?? this.targetBedtime,
      targetWakeTime: targetWakeTime ?? this.targetWakeTime,
      weekdayBedtime: weekdayBedtime ?? this.weekdayBedtime,
      weekdayWakeTime: weekdayWakeTime ?? this.weekdayWakeTime,
      weekendBedtime: weekendBedtime ?? this.weekendBedtime,
      weekendWakeTime: weekendWakeTime ?? this.weekendWakeTime,
      sleepConcerns: sleepConcerns ?? this.sleepConcerns,
      caffeineHabit: caffeineHabit ?? this.caffeineHabit,
      alcoholHabit: alcoholHabit ?? this.alcoholHabit,
      exerciseHabit: exerciseHabit ?? this.exerciseHabit,
      phoneUsageTime: phoneUsageTime ?? this.phoneUsageTime,
      phoneUsageContent: phoneUsageContent ?? this.phoneUsageContent,
      points: points ?? this.points,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notificationSettings: notificationSettings ?? this.notificationSettings,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconPath;
  final DateTime? unlockedAt;
  final int points;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    this.unlockedAt,
    this.points = 10,
  });

  bool get isUnlocked => unlockedAt != null;

  Achievement unlock() {
    return Achievement(
      id: id,
      name: name,
      description: description,
      iconPath: iconPath,
      unlockedAt: DateTime.now(),
      points: points,
    );
  }
}

class NotificationSettings {
  final bool bedtimeReminderEnabled;
  final int bedtimeReminderMinutes;
  final bool wakeUpAlarmEnabled;
  final bool sleepQualityNotificationEnabled;
  final bool weeklyReportEnabled;

  NotificationSettings({
    this.bedtimeReminderEnabled = true,
    this.bedtimeReminderMinutes = 30,
    this.wakeUpAlarmEnabled = false,
    this.sleepQualityNotificationEnabled = true,
    this.weeklyReportEnabled = true,
  });

  NotificationSettings copyWith({
    bool? bedtimeReminderEnabled,
    int? bedtimeReminderMinutes,
    bool? wakeUpAlarmEnabled,
    bool? sleepQualityNotificationEnabled,
    bool? weeklyReportEnabled,
  }) {
    return NotificationSettings(
      bedtimeReminderEnabled: bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      bedtimeReminderMinutes: bedtimeReminderMinutes ?? this.bedtimeReminderMinutes,
      wakeUpAlarmEnabled: wakeUpAlarmEnabled ?? this.wakeUpAlarmEnabled,
      sleepQualityNotificationEnabled: sleepQualityNotificationEnabled ?? this.sleepQualityNotificationEnabled,
      weeklyReportEnabled: weeklyReportEnabled ?? this.weeklyReportEnabled,
    );
  }
}