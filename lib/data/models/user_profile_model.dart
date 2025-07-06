import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class UserProfileModel {
  final String id;
  final double targetSleepHours;
  final String targetBedtime;
  final String targetWakeTime;
  final int points;
  final String? achievementsJson;
  final int createdAtEpoch;
  final int updatedAtEpoch;

  UserProfileModel({
    required this.id,
    required this.targetSleepHours,
    required this.targetBedtime,
    required this.targetWakeTime,
    required this.points,
    this.achievementsJson,
    required this.createdAtEpoch,
    required this.updatedAtEpoch,
  });

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      targetSleepHours: entity.targetSleepHours,
      targetBedtime: _timeOfDayToString(entity.targetBedtime),
      targetWakeTime: _timeOfDayToString(entity.targetWakeTime),
      points: entity.points,
      achievementsJson: _achievementsToJson(entity.achievements),
      createdAtEpoch: entity.createdAt.millisecondsSinceEpoch,
      updatedAtEpoch: entity.updatedAt.millisecondsSinceEpoch,
    );
  }

  UserProfile toEntity() {
    return UserProfile(
      id: id,
      targetSleepHours: targetSleepHours,
      targetBedtime: _stringToTimeOfDay(targetBedtime),
      targetWakeTime: _stringToTimeOfDay(targetWakeTime),
      points: points,
      achievements: _achievementsFromJson(achievementsJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAtEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_sleep_hours': targetSleepHours,
      'target_bedtime': targetBedtime,
      'target_wake_time': targetWakeTime,
      'points': points,
      'achievements_json': achievementsJson,
      'created_at': createdAtEpoch,
      'updated_at': updatedAtEpoch,
    };
  }

  factory UserProfileModel.fromMap(Map<String, dynamic> map) {
    return UserProfileModel(
      id: map['id'] as String,
      targetSleepHours: map['target_sleep_hours'] as double,
      targetBedtime: map['target_bedtime'] as String,
      targetWakeTime: map['target_wake_time'] as String,
      points: map['points'] as int,
      achievementsJson: map['achievements_json'] as String?,
      createdAtEpoch: map['created_at'] as int,
      updatedAtEpoch: map['updated_at'] as int,
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
}