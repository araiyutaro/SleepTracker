import 'package:flutter/material.dart';

/// 日次集計データエンティティ
/// 睡眠記録から計算された1日分の集計データを保持
class DailyAggregateData {
  final String id;
  final String userId;
  final DateTime date;
  final Duration? sleepDuration;
  final double? sleepQuality;
  final TimeOfDay? bedtime;
  final TimeOfDay? wakeTime;
  final int? movementCount;
  final Map<String, double>? sleepStagePercentages;
  final DayType dayType;
  final DateTime createdAt;

  const DailyAggregateData({
    required this.id,
    required this.userId,
    required this.date,
    this.sleepDuration,
    this.sleepQuality,
    this.bedtime,
    this.wakeTime,
    this.movementCount,
    this.sleepStagePercentages,
    required this.dayType,
    required this.createdAt,
  });

  /// 睡眠セッションから日次集計データを生成
  factory DailyAggregateData.fromSleepSession({
    required String userId,
    required DateTime date,
    required Duration sleepDuration,
    required double sleepQuality,
    required TimeOfDay bedtime,
    required TimeOfDay wakeTime,
    int? movementCount,
    Map<String, double>? sleepStagePercentages,
  }) {
    return DailyAggregateData(
      id: '${userId}_${date.toIso8601String().split('T')[0]}',
      userId: userId,
      date: date,
      sleepDuration: sleepDuration,
      sleepQuality: sleepQuality,
      bedtime: bedtime,
      wakeTime: wakeTime,
      movementCount: movementCount,
      sleepStagePercentages: sleepStagePercentages,
      dayType: _determineDayType(date),
      createdAt: DateTime.now(),
    );
  }

  /// 日付から平日/休日を判定
  static DayType _determineDayType(DateTime date) {
    // 土曜日(6)、日曜日(7)を休日とする
    return (date.weekday == 6 || date.weekday == 7) 
        ? DayType.weekend 
        : DayType.weekday;
  }

  /// データベース保存用のマップに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0],
      'sleep_duration_minutes': sleepDuration?.inMinutes,
      'sleep_quality': sleepQuality,
      'bedtime_hour': bedtime?.hour,
      'bedtime_minute': bedtime?.minute,
      'wake_time_hour': wakeTime?.hour,
      'wake_time_minute': wakeTime?.minute,
      'movement_count': movementCount,
      'deep_sleep_percentage': sleepStagePercentages?['deep'],
      'light_sleep_percentage': sleepStagePercentages?['light'],
      'rem_sleep_percentage': sleepStagePercentages?['rem'],
      'awake_percentage': sleepStagePercentages?['awake'],
      'day_type': dayType.toString().split('.').last,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// データベースのマップから復元
  factory DailyAggregateData.fromMap(Map<String, dynamic> map) {
    return DailyAggregateData(
      id: map['id'],
      userId: map['user_id'],
      date: DateTime.parse(map['date']),
      sleepDuration: map['sleep_duration_minutes'] != null
          ? Duration(minutes: map['sleep_duration_minutes'])
          : null,
      sleepQuality: map['sleep_quality']?.toDouble(),
      bedtime: map['bedtime_hour'] != null && map['bedtime_minute'] != null
          ? TimeOfDay(hour: map['bedtime_hour'], minute: map['bedtime_minute'])
          : null,
      wakeTime: map['wake_time_hour'] != null && map['wake_time_minute'] != null
          ? TimeOfDay(hour: map['wake_time_hour'], minute: map['wake_time_minute'])
          : null,
      movementCount: map['movement_count'],
      sleepStagePercentages: _buildSleepStagePercentages(map),
      dayType: DayType.values.firstWhere(
        (e) => e.toString().split('.').last == map['day_type'],
        orElse: () => DayType.weekday,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  /// 睡眠段階パーセンテージのマップを構築
  static Map<String, double>? _buildSleepStagePercentages(Map<String, dynamic> map) {
    if (map['deep_sleep_percentage'] == null &&
        map['light_sleep_percentage'] == null &&
        map['rem_sleep_percentage'] == null &&
        map['awake_percentage'] == null) {
      return null;
    }

    return {
      'deep': map['deep_sleep_percentage']?.toDouble() ?? 0.0,
      'light': map['light_sleep_percentage']?.toDouble() ?? 0.0,
      'rem': map['rem_sleep_percentage']?.toDouble() ?? 0.0,
      'awake': map['awake_percentage']?.toDouble() ?? 0.0,
    };
  }

  /// 睡眠時間を時間:分形式で取得
  String get sleepDurationFormatted {
    if (sleepDuration == null) return '---';
    final hours = sleepDuration!.inHours;
    final minutes = sleepDuration!.inMinutes.remainder(60);
    return '${hours}時間${minutes}分';
  }

  /// 睡眠品質を％形式で取得
  String get sleepQualityFormatted {
    if (sleepQuality == null) return '---';
    return '${sleepQuality!.toInt()}%';
  }

  /// 就寝時刻を文字列で取得
  String get bedtimeFormatted {
    if (bedtime == null) return '---';
    return '${bedtime!.hour.toString().padLeft(2, '0')}:${bedtime!.minute.toString().padLeft(2, '0')}';
  }

  /// 起床時刻を文字列で取得
  String get wakeTimeFormatted {
    if (wakeTime == null) return '---';
    return '${wakeTime!.hour.toString().padLeft(2, '0')}:${wakeTime!.minute.toString().padLeft(2, '0')}';
  }

  /// 平日/休日の判定
  bool get isWeekend => dayType == DayType.weekend;

  @override
  String toString() {
    return 'DailyAggregateData(id: $id, date: $date, sleepDuration: $sleepDuration, quality: $sleepQuality, dayType: $dayType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyAggregateData && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 平日/休日の区分
enum DayType {
  weekday,  // 平日
  weekend,  // 休日
}

/// 平日/休日の区分を日本語で取得する拡張
extension DayTypeExtension on DayType {
  String get displayName {
    switch (this) {
      case DayType.weekday:
        return '平日';
      case DayType.weekend:
        return '休日';
    }
  }
}