import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/entities/daily_aggregate_data.dart';
import '../domain/entities/sleep_statistics.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/sleep_session.dart';
import '../data/models/sleep_record_model.dart';
import 'database_service.dart';

/// 個人分析サービス
/// ユーザー個人の睡眠データを分析し、統計情報や改善提案を提供
class PersonalAnalyticsService {
  final DatabaseService _databaseService = DatabaseService();

  /// 基本統計を計算（過去30日間）
  Future<SleepStatistics> calculateBasicStatistics(String userId) async {
    final db = await _databaseService.database;
    
    // 過去30日間の睡眠セッションデータを取得
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final result = await db.query(
      'sleep_records',
      where: 'start_time >= ?',
      whereArgs: [thirtyDaysAgo.millisecondsSinceEpoch],
      orderBy: 'start_time DESC',
    );

    if (result.isEmpty) {
      return const SleepStatistics(
        averageSleepDuration: Duration.zero,
        averageSleepQuality: 0.0,
        consistencyScore: 0.0,
        weeklyTrends: {},
        totalRecords: 0,
      );
    }

    final sessions = result.map((map) => SleepRecordModel.fromMap(map).toEntity()).toList();
    
    // セッションから統計データを計算
    final validDurations = sessions
        .map((session) => session.calculatedDuration)
        .toList();
    
    final validQualities = sessions
        .where((session) => session.qualityScore != null)
        .map((session) => session.qualityScore!)
        .toList();

    final averageDuration = validDurations.isNotEmpty
        ? Duration(minutes: validDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/ validDurations.length)
        : Duration.zero;

    final averageQuality = validQualities.isNotEmpty
        ? validQualities.reduce((a, b) => a + b) / validQualities.length
        : 0.0;

    final consistencyScore = _calculateConsistencyScore(sessions);

    return SleepStatistics(
      averageSleepDuration: averageDuration,
      averageSleepQuality: averageQuality,
      consistencyScore: consistencyScore,
      weeklyTrends: {},
      totalRecords: sessions.length,
      shortestSleep: validDurations.isNotEmpty ? validDurations.reduce((a, b) => a.inMinutes < b.inMinutes ? a : b) : null,
      longestSleep: validDurations.isNotEmpty ? validDurations.reduce((a, b) => a.inMinutes > b.inMinutes ? a : b) : null,
      highestQuality: validQualities.isNotEmpty ? validQualities.reduce(max) : null,
      lowestQuality: validQualities.isNotEmpty ? validQualities.reduce(min) : null,
    );
  }

  /// 睡眠トレンドを計算（週別推移）
  Future<List<WeeklyTrend>> calculateWeeklyTrends(String userId, int weeks) async {
    final db = await _databaseService.database;
    
    final trends = <WeeklyTrend>[];
    
    for (int i = 0; i < weeks; i++) {
      final weekStart = DateTime.now().subtract(Duration(days: (i + 1) * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      
      final result = await db.query(
        'sleep_records',
        where: 'start_time >= ? AND start_time < ?',
        whereArgs: [
          weekStart.millisecondsSinceEpoch,
          weekEnd.millisecondsSinceEpoch,
        ],
      );

      if (result.isNotEmpty) {
        final weekSessions = result.map((map) => SleepRecordModel.fromMap(map).toEntity()).toList();
        
        final validDurations = weekSessions
            .map((session) => session.calculatedDuration)
            .toList();
        
        final validQualities = weekSessions
            .where((session) => session.qualityScore != null)
            .map((session) => session.qualityScore!)
            .toList();

        if (validDurations.isNotEmpty && validQualities.isNotEmpty) {
          final averageDuration = Duration(
            minutes: validDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/ validDurations.length,
          );
          final averageQuality = validQualities.reduce((a, b) => a + b) / validQualities.length;

          trends.add(WeeklyTrend(
            weekStart: weekStart,
            averageDuration: averageDuration,
            averageQuality: averageQuality,
            recordCount: weekSessions.length,
          ));
        }
      }
    }

    return trends.reversed.toList(); // 古い順に並べ替え
  }

  /// 平日/休日パターン分析
  Future<PatternAnalysis> analyzeWeekdayWeekendPatterns(String userId) async {
    final db = await _databaseService.database;
    
    // 過去30日間のデータを取得
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final result = await db.query(
      'sleep_records',
      where: 'start_time >= ?',
      whereArgs: [thirtyDaysAgo.millisecondsSinceEpoch],
    );

    final sessions = result.map((map) => SleepRecordModel.fromMap(map).toEntity()).toList();
    
    final weekdaySessions = sessions.where((session) {
      final weekday = session.startTime.weekday;
      return weekday >= 1 && weekday <= 5; // Monday to Friday
    }).toList();
    
    final weekendSessions = sessions.where((session) {
      final weekday = session.startTime.weekday;
      return weekday == 6 || weekday == 7; // Saturday and Sunday
    }).toList();

    // 平日の平均を計算
    final weekdayDurations = weekdaySessions
        .map((session) => session.calculatedDuration)
        .toList();
    
    final weekdayQualities = weekdaySessions
        .where((session) => session.qualityScore != null)
        .map((session) => session.qualityScore!)
        .toList();

    // 休日の平均を計算
    final weekendDurations = weekendSessions
        .map((session) => session.calculatedDuration)
        .toList();
    
    final weekendQualities = weekendSessions
        .where((session) => session.qualityScore != null)
        .map((session) => session.qualityScore!)
        .toList();

    final weekdayAvgDuration = weekdayDurations.isNotEmpty
        ? Duration(minutes: weekdayDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/ weekdayDurations.length)
        : Duration.zero;

    final weekendAvgDuration = weekendDurations.isNotEmpty
        ? Duration(minutes: weekendDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/ weekendDurations.length)
        : Duration.zero;

    final weekdayAvgQuality = weekdayQualities.isNotEmpty
        ? weekdayQualities.reduce((a, b) => a + b) / weekdayQualities.length
        : 0.0;

    final weekendAvgQuality = weekendQualities.isNotEmpty
        ? weekendQualities.reduce((a, b) => a + b) / weekendQualities.length
        : 0.0;

    // 社会的ジェットラグを計算（休日と平日の睡眠時間の差）
    final socialJetlag = Duration(
      minutes: (weekendAvgDuration.inMinutes - weekdayAvgDuration.inMinutes).abs(),
    );

    return PatternAnalysis(
      weekdayAverageDuration: weekdayAvgDuration,
      weekendAverageDuration: weekendAvgDuration,
      weekdayAverageQuality: weekdayAvgQuality,
      weekendAverageQuality: weekendAvgQuality,
      socialJetlag: socialJetlag,
    );
  }

  /// 改善提案を生成
  Future<List<SleepRecommendation>> generateRecommendations(String userId) async {
    final recommendations = <SleepRecommendation>[];
    
    // 基本統計とユーザープロファイルを取得
    final stats = await calculateBasicStatistics(userId);
    final userProfile = await _getUserProfile(userId);
    
    if (userProfile == null) return recommendations;

    // 睡眠時間不足の場合
    if (stats.averageSleepDuration.inHours < 7) {
      recommendations.add(SleepRecommendation(
        type: RecommendationType.sleepDuration,
        title: '睡眠時間を増やしましょう',
        description: '理想的な睡眠時間は7-9時間です。就寝時刻を30分早めることをおすすめします。',
        priority: Priority.high,
        createdAt: DateTime.now(),
      ));
    }

    // 規則性が低い場合
    if (stats.consistencyScore < 70) {
      recommendations.add(SleepRecommendation(
        type: RecommendationType.consistency,
        title: '睡眠リズムを整えましょう',
        description: '毎日同じ時間に寝起きすることで、睡眠の質が向上します。',
        priority: Priority.medium,
        createdAt: DateTime.now(),
      ));
    }

    // スマホ利用時間が長い場合
    if (userProfile.phoneUsageTime == '1時間～2時間' || 
        userProfile.phoneUsageTime == '2時間以上') {
      recommendations.add(SleepRecommendation(
        type: RecommendationType.phoneUsage,
        title: '就寝前のスマホ時間を減らしましょう',
        description: 'ブルーライトが睡眠の質に影響する可能性があります。',
        priority: Priority.medium,
        createdAt: DateTime.now(),
      ));
    }

    // 睡眠品質が低い場合
    if (stats.averageSleepQuality < 70) {
      recommendations.add(SleepRecommendation(
        type: RecommendationType.qualityImprovement,
        title: '睡眠品質を向上させましょう',
        description: '睡眠環境の改善や規則的な生活習慣が睡眠品質向上につながります。',
        priority: Priority.medium,
        createdAt: DateTime.now(),
      ));
    }

    return recommendations;
  }

  /// 目標達成度を計算
  Future<GoalProgress> calculateGoalProgress(String userId) async {
    final db = await _databaseService.database;
    final userProfile = await _getUserProfile(userId);
    
    if (userProfile == null) {
      return const GoalProgress(
        totalDays: 0,
        sleepDurationGoalAchieved: 0,
        bedtimeGoalAchieved: 0,
        qualityGoalAchieved: 0,
        overallProgress: 0.0,
      );
    }

    // 過去7日間のデータを取得
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final result = await db.query(
      'sleep_records',
      where: 'start_time >= ?',
      whereArgs: [sevenDaysAgo.millisecondsSinceEpoch],
    );

    if (result.isEmpty) {
      return const GoalProgress(
        totalDays: 0,
        sleepDurationGoalAchieved: 0,
        bedtimeGoalAchieved: 0,
        qualityGoalAchieved: 0,
        overallProgress: 0.0,
      );
    }

    final sessions = result.map((map) => SleepRecordModel.fromMap(map).toEntity()).toList();
    
    int sleepDurationGoalAchieved = 0;
    int bedtimeGoalAchieved = 0;
    int qualityGoalAchieved = 0;

    // 目標睡眠時間を分に変換
    final targetSleepMinutes = (userProfile.targetSleepHours * 60).round();
    
    for (final session in sessions) {
      // 睡眠時間目標達成チェック
      final actualMinutes = session.calculatedDuration.inMinutes;
      // 目標時間の±30分以内なら達成とみなす
      if ((actualMinutes - targetSleepMinutes).abs() <= 30) {
        sleepDurationGoalAchieved++;
      }

      // 就寝時刻目標達成チェック
      final targetMinutes = userProfile.targetBedtime.hour * 60 + userProfile.targetBedtime.minute;
      final actualBedtimeMinutes = session.startTime.hour * 60 + session.startTime.minute;
      // 目標時刻の±30分以内なら達成とみなす
      if ((actualBedtimeMinutes - targetMinutes).abs() <= 30) {
        bedtimeGoalAchieved++;
      }

      // 睡眠品質目標達成チェック（80%以上を目標とする）
      if (session.qualityScore != null && session.qualityScore! >= 80) {
        qualityGoalAchieved++;
      }
    }

    final totalDays = sessions.length;
    final overallProgress = totalDays > 0 
        ? (sleepDurationGoalAchieved + bedtimeGoalAchieved + qualityGoalAchieved) / (totalDays * 3) 
        : 0.0;

    return GoalProgress(
      totalDays: totalDays,
      sleepDurationGoalAchieved: sleepDurationGoalAchieved,
      bedtimeGoalAchieved: bedtimeGoalAchieved,
      qualityGoalAchieved: qualityGoalAchieved,
      overallProgress: overallProgress,
    );
  }

  /// 日次集計データを保存
  Future<void> saveDailyAggregate(DailyAggregateData data) async {
    final db = await _databaseService.database;
    
    await db.insert(
      'daily_sleep_aggregates',
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 睡眠セッションから日次集計データを生成して保存
  Future<void> processSleepSessionAggregate(SleepSession sleepSession) async {
    if (sleepSession.endTime == null) return;
    
    final aggregateData = DailyAggregateData.fromSleepSession(
      userId: 'default_user', // 実際のユーザーIDに置き換え
      date: sleepSession.startTime,
      sleepDuration: sleepSession.calculatedDuration,
      sleepQuality: sleepSession.qualityScore ?? 0.0,
      bedtime: TimeOfDay.fromDateTime(sleepSession.startTime),
      wakeTime: TimeOfDay.fromDateTime(sleepSession.endTime!),
      movementCount: sleepSession.movements.length,
      sleepStagePercentages: sleepSession.sleepStages != null ? {
        'deep': sleepSession.sleepStages!.deepSleepPercentage,
        'light': sleepSession.sleepStages!.lightSleepPercentage,
        'rem': sleepSession.sleepStages!.remSleepPercentage,
        'awake': sleepSession.sleepStages!.awakePercentage,
      } : null,
    );

    await saveDailyAggregate(aggregateData);
  }

  /// 規則性スコアを計算
  double _calculateConsistencyScore(List<SleepSession> sessions) {
    if (sessions.length < 7) return 0.0;

    // 就寝時刻の標準偏差を計算
    final bedtimes = sessions
        .map((session) => session.startTime.hour * 60 + session.startTime.minute)
        .toList();

    if (bedtimes.isEmpty) return 0.0;

    final mean = bedtimes.reduce((a, b) => a + b) / bedtimes.length;
    final variance = bedtimes
        .map((time) => pow(time - mean, 2))
        .reduce((a, b) => a + b) / bedtimes.length;
    final standardDeviation = sqrt(variance);

    // 標準偏差が小さいほど規則的（最大120分で正規化）
    return max(0.0, (120 - standardDeviation) / 120 * 100);
  }

  /// ユーザープロファイルを取得
  Future<UserProfile?> _getUserProfile(String userId) async {
    // TODO: 実際のユーザープロファイル取得の実装
    // 現在はダミーデータを返す
    return UserProfile(
      id: userId,
      targetSleepHours: 8.0,
      phoneUsageTime: '30分～1時間',
    );
  }
}