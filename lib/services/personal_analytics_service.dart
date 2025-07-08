import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../domain/entities/daily_aggregate_data.dart';
import '../domain/entities/sleep_statistics.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/sleep_record.dart';
import 'database_service.dart';

/// 個人分析サービス
/// ユーザー個人の睡眠データを分析し、統計情報や改善提案を提供
class PersonalAnalyticsService {
  final DatabaseService _databaseService = DatabaseService();

  /// 基本統計を計算（過去30日間）
  Future<SleepStatistics> calculateBasicStatistics(String userId) async {
    final db = await _databaseService.database;
    
    // 過去30日間の集計データを取得
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final result = await db.query(
      'daily_sleep_aggregates',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, thirtyDaysAgo.toIso8601String().split('T')[0]],
      orderBy: 'date DESC',
    );

    if (result.isEmpty) {
      return SleepStatistics(
        averageSleepDuration: Duration.zero,
        averageSleepQuality: 0.0,
        consistencyScore: 0.0,
        weeklyTrends: {},
        totalRecords: 0,
      );
    }

    final dailyData = result.map((map) => DailyAggregateData.fromMap(map)).toList();
    
    // 基本統計を計算
    final validDurations = dailyData
        .where((data) => data.sleepDuration != null)
        .map((data) => data.sleepDuration!)
        .toList();
    
    final validQualities = dailyData
        .where((data) => data.sleepQuality != null)
        .map((data) => data.sleepQuality!)
        .toList();

    final averageDuration = validDurations.isNotEmpty
        ? Duration(minutes: validDurations.map((d) => d.inMinutes).reduce((a, b) => a + b) ~/ validDurations.length)
        : Duration.zero;

    final averageQuality = validQualities.isNotEmpty
        ? validQualities.reduce((a, b) => a + b) / validQualities.length
        : 0.0;

    final consistencyScore = _calculateConsistencyScore(dailyData);

    return SleepStatistics(
      averageSleepDuration: averageDuration,
      averageSleepQuality: averageQuality,
      consistencyScore: consistencyScore,
      weeklyTrends: {},
      totalRecords: dailyData.length,
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
        'daily_sleep_aggregates',
        where: 'user_id = ? AND date >= ? AND date < ?',
        whereArgs: [
          userId,
          weekStart.toIso8601String().split('T')[0],
          weekEnd.toIso8601String().split('T')[0],
        ],
      );

      if (result.isNotEmpty) {
        final weekData = result.map((map) => DailyAggregateData.fromMap(map)).toList();
        
        final validDurations = weekData
            .where((data) => data.sleepDuration != null)
            .map((data) => data.sleepDuration!)
            .toList();
        
        final validQualities = weekData
            .where((data) => data.sleepQuality != null)
            .map((data) => data.sleepQuality!)
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
            recordCount: weekData.length,
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
      'daily_sleep_aggregates',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, thirtyDaysAgo.toIso8601String().split('T')[0]],
    );

    final dailyData = result.map((map) => DailyAggregateData.fromMap(map)).toList();
    
    final weekdayData = dailyData.where((data) => data.dayType == DayType.weekday).toList();
    final weekendData = dailyData.where((data) => data.dayType == DayType.weekend).toList();

    // 平日の平均を計算
    final weekdayDurations = weekdayData
        .where((data) => data.sleepDuration != null)
        .map((data) => data.sleepDuration!)
        .toList();
    
    final weekdayQualities = weekdayData
        .where((data) => data.sleepQuality != null)
        .map((data) => data.sleepQuality!)
        .toList();

    // 休日の平均を計算
    final weekendDurations = weekendData
        .where((data) => data.sleepDuration != null)
        .map((data) => data.sleepDuration!)
        .toList();
    
    final weekendQualities = weekendData
        .where((data) => data.sleepQuality != null)
        .map((data) => data.sleepQuality!)
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
      'daily_sleep_aggregates',
      where: 'user_id = ? AND date >= ?',
      whereArgs: [userId, sevenDaysAgo.toIso8601String().split('T')[0]],
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

    final dailyData = result.map((map) => DailyAggregateData.fromMap(map)).toList();
    
    int sleepDurationGoalAchieved = 0;
    int bedtimeGoalAchieved = 0;
    int qualityGoalAchieved = 0;

    // 目標睡眠時間を分に変換
    final targetSleepMinutes = (userProfile.targetSleepHours * 60).round();
    
    for (final data in dailyData) {
      // 睡眠時間目標達成チェック
      if (data.sleepDuration != null) {
        final actualMinutes = data.sleepDuration!.inMinutes;
        // 目標時間の±30分以内なら達成とみなす
        if ((actualMinutes - targetSleepMinutes).abs() <= 30) {
          sleepDurationGoalAchieved++;
        }
      }

      // 就寝時刻目標達成チェック
      if (data.bedtime != null && userProfile.targetBedtime != null) {
        final targetMinutes = userProfile.targetBedtime!.hour * 60 + userProfile.targetBedtime!.minute;
        final actualMinutes = data.bedtime!.hour * 60 + data.bedtime!.minute;
        // 目標時刻の±30分以内なら達成とみなす
        if ((actualMinutes - targetMinutes).abs() <= 30) {
          bedtimeGoalAchieved++;
        }
      }

      // 睡眠品質目標達成チェック（80%以上を目標とする）
      if (data.sleepQuality != null && data.sleepQuality! >= 80) {
        qualityGoalAchieved++;
      }
    }

    final totalDays = dailyData.length;
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
  Future<void> processSleepSessionAggregate(SleepRecord sleepRecord) async {
    if (sleepRecord.endTime == null) return;
    
    final aggregateData = DailyAggregateData.fromSleepSession(
      userId: 'default_user', // 実際のユーザーIDに置き換え
      date: DateTime.fromMillisecondsSinceEpoch(sleepRecord.startTime),
      sleepDuration: sleepRecord.duration!,
      sleepQuality: sleepRecord.qualityScore ?? 0.0,
      bedtime: TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(sleepRecord.startTime)),
      wakeTime: TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(sleepRecord.endTime!)),
    );

    await saveDailyAggregate(aggregateData);
  }

  /// 規則性スコアを計算
  double _calculateConsistencyScore(List<DailyAggregateData> dailyData) {
    if (dailyData.length < 7) return 0.0;

    // 就寝時刻の標準偏差を計算
    final bedtimes = dailyData
        .where((d) => d.bedtime != null)
        .map((d) => d.bedtime!.hour * 60 + d.bedtime!.minute)
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
    final db = await _databaseService.database;
    
    final result = await db.query(
      'user_profiles',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    
    return UserProfile.fromMap(result.first);
  }
}