/// 睡眠統計データ
class SleepStatistics {
  final Duration averageSleepDuration;
  final double averageSleepQuality;
  final double consistencyScore; // 睡眠リズムの規則性（0-100）
  final Map<String, dynamic> weeklyTrends;
  final int totalRecords;
  final Duration? shortestSleep;
  final Duration? longestSleep;
  final double? highestQuality;
  final double? lowestQuality;

  const SleepStatistics({
    required this.averageSleepDuration,
    required this.averageSleepQuality,
    required this.consistencyScore,
    required this.weeklyTrends,
    required this.totalRecords,
    this.shortestSleep,
    this.longestSleep,
    this.highestQuality,
    this.lowestQuality,
  });

  /// 平均睡眠時間を時間:分形式で取得
  String get averageSleepDurationFormatted {
    final hours = averageSleepDuration.inHours;
    final minutes = averageSleepDuration.inMinutes.remainder(60);
    return '${hours}時間${minutes}分';
  }

  /// 平均睡眠品質を％形式で取得
  String get averageSleepQualityFormatted {
    return '${averageSleepQuality.toInt()}%';
  }

  /// 規則性スコアを％形式で取得
  String get consistencyScoreFormatted {
    return '${consistencyScore.toInt()}%';
  }
}

/// 週間トレンドデータ
class WeeklyTrend {
  final DateTime weekStart;
  final Duration averageDuration;
  final double averageQuality;
  final int recordCount;

  const WeeklyTrend({
    required this.weekStart,
    required this.averageDuration,
    required this.averageQuality,
    required this.recordCount,
  });
}

/// 平日/休日パターン分析
class PatternAnalysis {
  final Duration weekdayAverageDuration;
  final Duration weekendAverageDuration;
  final double weekdayAverageQuality;
  final double weekendAverageQuality;
  final Duration socialJetlag; // 社会的ジェットラグ（平日と休日の睡眠時間差）

  const PatternAnalysis({
    required this.weekdayAverageDuration,
    required this.weekendAverageDuration,
    required this.weekdayAverageQuality,
    required this.weekendAverageQuality,
    required this.socialJetlag,
  });

  /// 社会的ジェットラグを分で取得
  int get socialJetlagMinutes => socialJetlag.inMinutes;

  /// 社会的ジェットラグを時間:分形式で取得
  String get socialJetlagFormatted {
    final hours = socialJetlag.inHours;
    final minutes = socialJetlag.inMinutes.remainder(60);
    return '${hours}時間${minutes}分';
  }
}

/// 改善提案
class SleepRecommendation {
  final RecommendationType type;
  final String title;
  final String description;
  final Priority priority;
  final DateTime createdAt;

  const SleepRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.priority,
    required this.createdAt,
  });
}

/// 改善提案のタイプ
enum RecommendationType {
  sleepDuration,    // 睡眠時間
  consistency,      // 規則性
  phoneUsage,       // スマホ利用
  bedtimeOptimal,   // 就寝時刻最適化
  qualityImprovement, // 睡眠品質向上
}

/// 優先度
enum Priority {
  high,
  medium,
  low,
}

/// 目標達成度
class GoalProgress {
  final int totalDays;
  final int sleepDurationGoalAchieved;
  final int bedtimeGoalAchieved;
  final int qualityGoalAchieved;
  final double overallProgress;

  const GoalProgress({
    required this.totalDays,
    required this.sleepDurationGoalAchieved,
    required this.bedtimeGoalAchieved,
    required this.qualityGoalAchieved,
    required this.overallProgress,
  });

  /// 睡眠時間目標達成率
  double get sleepDurationAchievementRate {
    if (totalDays == 0) return 0.0;
    return sleepDurationGoalAchieved / totalDays;
  }

  /// 就寝時刻目標達成率
  double get bedtimeAchievementRate {
    if (totalDays == 0) return 0.0;
    return bedtimeGoalAchieved / totalDays;
  }

  /// 睡眠品質目標達成率
  double get qualityAchievementRate {
    if (totalDays == 0) return 0.0;
    return qualityGoalAchieved / totalDays;
  }
}