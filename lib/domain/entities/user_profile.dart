import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final double targetSleepHours;
  final TimeOfDay targetBedtime;
  final TimeOfDay targetWakeTime;
  final int points;
  final List<Achievement> achievements;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    this.targetSleepHours = 8.0,
    TimeOfDay? targetBedtime,
    TimeOfDay? targetWakeTime,
    this.points = 0,
    List<Achievement>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : targetBedtime = targetBedtime ?? const TimeOfDay(hour: 23, minute: 0),
        targetWakeTime = targetWakeTime ?? const TimeOfDay(hour: 7, minute: 0),
        achievements = achievements ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  UserProfile copyWith({
    String? id,
    double? targetSleepHours,
    TimeOfDay? targetBedtime,
    TimeOfDay? targetWakeTime,
    int? points,
    List<Achievement>? achievements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      targetSleepHours: targetSleepHours ?? this.targetSleepHours,
      targetBedtime: targetBedtime ?? this.targetBedtime,
      targetWakeTime: targetWakeTime ?? this.targetWakeTime,
      points: points ?? this.points,
      achievements: achievements ?? this.achievements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
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