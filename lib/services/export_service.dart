import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../domain/entities/sleep_session.dart';
import '../domain/repositories/sleep_repository.dart';

class ExportService {
  final SleepRepository _sleepRepository;

  ExportService({required SleepRepository sleepRepository})
      : _sleepRepository = sleepRepository;

  Future<String> exportToCSV({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await _sleepRepository.getSessions(
      from: startDate,
      to: endDate,
    );

    final csvData = StringBuffer();
    csvData.writeln('日付,開始時刻,終了時刻,睡眠時間(分),睡眠時間(時間),睡眠品質(%),深い睡眠(%),浅い睡眠(%),REM睡眠(%),覚醒(%),動き回数');

    for (final session in sessions) {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');
      final startTime = timeFormat.format(session.startTime);
      final endTime = session.endTime != null ? timeFormat.format(session.endTime!) : '';
      final durationMinutes = session.duration?.inMinutes ?? 0;
      final durationHours = (durationMinutes / 60).toStringAsFixed(1);
      final quality = session.qualityScore?.toStringAsFixed(1) ?? '';
      final deepSleep = session.sleepStages?.deepSleepPercentage?.toStringAsFixed(1) ?? '';
      final lightSleep = session.sleepStages?.lightSleepPercentage?.toStringAsFixed(1) ?? '';
      final remSleep = session.sleepStages?.remSleepPercentage?.toStringAsFixed(1) ?? '';
      final awake = session.sleepStages?.awakePercentage?.toStringAsFixed(1) ?? '';
      final movements = session.sleepStages?.movementCount?.toString() ?? '';

      csvData.writeln('${dateFormat.format(session.startTime)},$startTime,$endTime,$durationMinutes,$durationHours,$quality,$deepSleep,$lightSleep,$remSleep,$awake,$movements');
    }

    return csvData.toString();
  }

  Future<String> exportToJSON({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await _sleepRepository.getSessions(
      from: startDate,
      to: endDate,
    );

    final jsonData = {
      'export_date': DateTime.now().toIso8601String(),
      'period': {
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
      },
      'sessions': sessions.map((session) => {
        'id': session.id,
        'start_time': session.startTime.toIso8601String(),
        'end_time': session.endTime?.toIso8601String(),
        'duration_minutes': session.duration?.inMinutes,
        'quality_score': session.qualityScore,
        'sleep_stages': session.sleepStages != null ? {
          'deep_sleep_percentage': session.sleepStages!.deepSleepPercentage,
          'light_sleep_percentage': session.sleepStages!.lightSleepPercentage,
          'rem_sleep_percentage': session.sleepStages!.remSleepPercentage,
          'awake_percentage': session.sleepStages!.awakePercentage,
          'movement_count': session.sleepStages!.movementCount,
        } : null,
        'movements': session.movements?.map((movement) => {
          'timestamp': movement.timestamp.toIso8601String(),
          'intensity': movement.intensity,
        }).toList(),
      }).toList(),
    };

    return JsonEncoder.withIndent('  ').convert(jsonData);
  }

  Future<String> exportToText({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final sessions = await _sleepRepository.getSessions(
      from: startDate,
      to: endDate,
    );

    final textData = StringBuffer();
    textData.writeln('睡眠記録エクスポート');
    textData.writeln('エクスポート日時: ${DateFormat('yyyy年MM月dd日 HH:mm').format(DateTime.now())}');
    textData.writeln('期間: ${startDate != null ? DateFormat('yyyy年MM月dd日').format(startDate) : '全期間'} - ${endDate != null ? DateFormat('yyyy年MM月dd日').format(endDate) : '現在'}');
    textData.writeln('総記録数: ${sessions.length}');
    textData.writeln('');

    final weeklyData = _groupByWeek(sessions);
    
    textData.writeln('=== 週別まとめ ===');
    for (final week in weeklyData.entries) {
      textData.writeln('${week.key}:');
      textData.writeln('  記録数: ${week.value.length}');
      if (week.value.isNotEmpty) {
        final avgDuration = week.value
            .where((s) => s.duration != null)
            .map((s) => s.duration!.inMinutes)
            .reduce((a, b) => a + b) / week.value.length;
        final avgQuality = week.value
            .where((s) => s.qualityScore != null)
            .map((s) => s.qualityScore!)
            .reduce((a, b) => a + b) / week.value.where((s) => s.qualityScore != null).length;
        textData.writeln('  平均睡眠時間: ${(avgDuration / 60).toStringAsFixed(1)}時間');
        textData.writeln('  平均睡眠品質: ${avgQuality.toStringAsFixed(1)}%');
      }
      textData.writeln('');
    }

    textData.writeln('=== 詳細記録 ===');
    for (final session in sessions) {
      textData.writeln('日付: ${DateFormat('yyyy年MM月dd日').format(session.startTime)}');
      textData.writeln('開始時刻: ${DateFormat('HH:mm').format(session.startTime)}');
      textData.writeln('終了時刻: ${session.endTime != null ? DateFormat('HH:mm').format(session.endTime!) : '継続中'}');
      textData.writeln('睡眠時間: ${session.duration != null ? '${(session.duration!.inMinutes / 60).toStringAsFixed(1)}時間' : '不明'}');
      textData.writeln('睡眠品質: ${session.qualityScore != null ? '${session.qualityScore!.toStringAsFixed(1)}%' : '不明'}');
      
      if (session.sleepStages != null) {
        textData.writeln('睡眠段階:');
        textData.writeln('  深い睡眠: ${session.sleepStages!.deepSleepPercentage?.toStringAsFixed(1) ?? '不明'}%');
        textData.writeln('  浅い睡眠: ${session.sleepStages!.lightSleepPercentage?.toStringAsFixed(1) ?? '不明'}%');
        textData.writeln('  REM睡眠: ${session.sleepStages!.remSleepPercentage?.toStringAsFixed(1) ?? '不明'}%');
        textData.writeln('  覚醒: ${session.sleepStages!.awakePercentage?.toStringAsFixed(1) ?? '不明'}%');
        textData.writeln('  動き回数: ${session.sleepStages!.movementCount ?? '不明'}');
      }
      textData.writeln('');
    }

    return textData.toString();
  }

  Future<File> saveToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  Map<String, List<SleepSession>> _groupByWeek(List<SleepSession> sessions) {
    final Map<String, List<SleepSession>> weeklyData = {};
    
    for (final session in sessions) {
      final weekStart = session.startTime.subtract(Duration(days: session.startTime.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final weekLabel = '${DateFormat('MM/dd').format(weekStart)} - ${DateFormat('MM/dd').format(weekEnd)}';
      
      if (!weeklyData.containsKey(weekLabel)) {
        weeklyData[weekLabel] = [];
      }
      weeklyData[weekLabel]!.add(session);
    }
    
    return weeklyData;
  }
}