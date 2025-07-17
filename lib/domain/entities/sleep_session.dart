class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double? qualityScore;
  final int? wakeQuality; // 目覚めの質 (1-5段階)
  final List<MovementData> movements;
  final DateTime createdAt;
  final SleepStageData? sleepStages;

  SleepSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.duration,
    this.qualityScore,
    this.wakeQuality,
    List<MovementData>? movements,
    DateTime? createdAt,
    this.sleepStages,
  })  : movements = movements ?? [],
        createdAt = createdAt ?? DateTime.now();

  bool get isActive => endTime == null;

  Duration get calculatedDuration {
    if (duration != null) return duration!;
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  SleepSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    double? qualityScore,
    int? wakeQuality,
    List<MovementData>? movements,
    DateTime? createdAt,
    SleepStageData? sleepStages,
  }) {
    return SleepSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      qualityScore: qualityScore ?? this.qualityScore,
      wakeQuality: wakeQuality ?? this.wakeQuality,
      movements: movements ?? this.movements,
      createdAt: createdAt ?? this.createdAt,
      sleepStages: sleepStages ?? this.sleepStages,
    );
  }
}

class MovementData {
  final DateTime timestamp;
  final double intensity;

  MovementData({
    required this.timestamp,
    required this.intensity,
  });
}

class SleepStageData {
  final double deepSleepPercentage;
  final double lightSleepPercentage;
  final double remSleepPercentage;
  final double awakePercentage;
  final int movementCount;

  SleepStageData({
    required this.deepSleepPercentage,
    required this.lightSleepPercentage,
    required this.remSleepPercentage,
    required this.awakePercentage,
    required this.movementCount,
  });

  double get totalSleep => deepSleepPercentage + lightSleepPercentage + remSleepPercentage;
}