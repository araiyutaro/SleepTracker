import '../../domain/entities/sleep_session.dart';

class SleepRecordModel {
  final String id;
  final int startTimeEpoch;
  final int? endTimeEpoch;
  final int? durationMinutes;
  final double? qualityScore;
  final int? wakeQuality;
  final String? movementsJson;
  final int createdAtEpoch;
  final String? sleepStagesJson;

  SleepRecordModel({
    required this.id,
    required this.startTimeEpoch,
    this.endTimeEpoch,
    this.durationMinutes,
    this.qualityScore,
    this.wakeQuality,
    this.movementsJson,
    required this.createdAtEpoch,
    this.sleepStagesJson,
  });

  factory SleepRecordModel.fromEntity(SleepSession entity) {
    return SleepRecordModel(
      id: entity.id,
      startTimeEpoch: entity.startTime.millisecondsSinceEpoch,
      endTimeEpoch: entity.endTime?.millisecondsSinceEpoch,
      durationMinutes: entity.duration?.inMinutes,
      qualityScore: entity.qualityScore,
      wakeQuality: entity.wakeQuality,
      movementsJson: _movementsToJson(entity.movements),
      createdAtEpoch: entity.createdAt.millisecondsSinceEpoch,
      sleepStagesJson: _sleepStagesToJson(entity.sleepStages),
    );
  }

  SleepSession toEntity() {
    return SleepSession(
      id: id,
      startTime: DateTime.fromMillisecondsSinceEpoch(startTimeEpoch),
      endTime: endTimeEpoch != null
          ? DateTime.fromMillisecondsSinceEpoch(endTimeEpoch!)
          : null,
      duration: durationMinutes != null
          ? Duration(minutes: durationMinutes!)
          : null,
      qualityScore: qualityScore,
      wakeQuality: wakeQuality,
      movements: _movementsFromJson(movementsJson),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAtEpoch),
      sleepStages: _sleepStagesFromJson(sleepStagesJson),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTimeEpoch,
      'end_time': endTimeEpoch,
      'duration_minutes': durationMinutes,
      'quality_score': qualityScore,
      'wake_quality': wakeQuality,
      'movements_json': movementsJson,
      'created_at': createdAtEpoch,
      'sleep_stages_json': sleepStagesJson,
    };
  }

  factory SleepRecordModel.fromMap(Map<String, dynamic> map) {
    return SleepRecordModel(
      id: map['id'] as String,
      startTimeEpoch: map['start_time'] as int,
      endTimeEpoch: map['end_time'] as int?,
      durationMinutes: map['duration_minutes'] as int?,
      qualityScore: map['quality_score'] as double?,
      wakeQuality: map['wake_quality'] as int?,
      movementsJson: map['movements_json'] as String?,
      createdAtEpoch: map['created_at'] as int,
      sleepStagesJson: map['sleep_stages_json'] as String?,
    );
  }

  static String? _movementsToJson(List<MovementData> movements) {
    if (movements.isEmpty) return null;
    return movements
        .map((m) => '${m.timestamp.millisecondsSinceEpoch}:${m.intensity}')
        .join(',');
  }

  static List<MovementData> _movementsFromJson(String? json) {
    if (json == null || json.isEmpty) return [];
    return json.split(',').map((item) {
      final parts = item.split(':');
      return MovementData(
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[0])),
        intensity: double.parse(parts[1]),
      );
    }).toList();
  }

  static String? _sleepStagesToJson(SleepStageData? stages) {
    if (stages == null) return null;
    return '${stages.deepSleepPercentage}:${stages.lightSleepPercentage}:'
           '${stages.remSleepPercentage}:${stages.awakePercentage}:${stages.movementCount}';
  }

  static SleepStageData? _sleepStagesFromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    final parts = json.split(':');
    if (parts.length != 5) return null;
    
    return SleepStageData(
      deepSleepPercentage: double.parse(parts[0]),
      lightSleepPercentage: double.parse(parts[1]),
      remSleepPercentage: double.parse(parts[2]),
      awakePercentage: double.parse(parts[3]),
      movementCount: int.parse(parts[4]),
    );
  }
}