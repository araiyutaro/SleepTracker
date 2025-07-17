import 'dart:math';
import 'package:uuid/uuid.dart';
import '../domain/entities/sleep_session.dart';
import '../domain/repositories/sleep_repository.dart';

class DummyDataGenerator {
  final SleepRepository _sleepRepository;
  final _uuid = const Uuid();
  final _random = Random();

  DummyDataGenerator({required SleepRepository sleepRepository})
      : _sleepRepository = sleepRepository;

  Future<void> generateDummySleepData() async {
    print('ダミー睡眠データの生成を開始...');
    
    // 既存のセッションを取得して重複チェック用に日付を抽出
    final existingSessions = await _sleepRepository.getSessions();
    final existingDates = existingSessions
        .map((session) => DateTime(session.startTime.year, session.startTime.month, session.startTime.day))
        .toSet();
    
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90)); // 3ヶ月前
    
    final sessions = <SleepSession>[];
    int skippedCount = 0;
    
    for (int i = 0; i < 90; i++) {
      final date = startDate.add(Duration(days: i));
      final dateOnly = DateTime(date.year, date.month, date.day);
      
      // 既存データがある日付はスキップ
      if (existingDates.contains(dateOnly)) {
        skippedCount++;
        print('日付 ${date.toIso8601String().split('T')[0]} はスキップ（既存データあり）');
        continue;
      }
      
      // 平日・休日で睡眠パターンを変える
      final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      
      final session = _generateSleepSession(date, isWeekend);
      sessions.add(session);
    }
    
    // セッションを保存
    for (final session in sessions) {
      try {
        await _sleepRepository.startSession(session);
        print('睡眠セッションを保存: ${session.startTime} - ${session.endTime}');
      } catch (e) {
        print('セッション保存エラー: $e');
      }
    }
    
    print('ダミーデータの生成完了: ${sessions.length}件生成、${skippedCount}件スキップ');
  }

  SleepSession _generateSleepSession(DateTime date, bool isWeekend) {
    // 睡眠開始時刻（平日: 22:30-24:30, 休日: 23:00-01:00）
    final bedtimeHour = isWeekend 
        ? 23 + _random.nextDouble() * 2  // 23:00-01:00
        : 22.5 + _random.nextDouble() * 2; // 22:30-24:30
    
    final bedtimeMinute = (bedtimeHour % 1) * 60;
    final actualBedtimeHour = bedtimeHour.floor();
    
    DateTime startTime = DateTime(
      date.year,
      date.month,
      date.day,
      actualBedtimeHour,
      bedtimeMinute.toInt(),
    );
    
    // 深夜を超える場合は翌日に調整
    if (actualBedtimeHour >= 24) {
      startTime = startTime.add(const Duration(days: 1));
    }
    
    // 睡眠時間（6-9時間、正規分布風）
    final sleepHours = _generateNormalDistribution(7.5, 1.0, 5.5, 9.5);
    final duration = Duration(minutes: (sleepHours * 60).round());
    final endTime = startTime.add(duration);
    
    // 睡眠品質スコア計算
    final qualityScore = _calculateQualityScore(duration);
    
    // 目覚めの質を生成（品質スコアと連動）
    final wakeQuality = _generateWakeQuality(qualityScore);
    
    // 動きデータ生成
    final movements = _generateMovements(startTime, duration);
    
    // 睡眠ステージデータ生成
    final sleepStages = _generateSleepStages();
    
    return SleepSession(
      id: _uuid.v4(),
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      qualityScore: qualityScore,
      wakeQuality: wakeQuality,
      movements: movements,
      createdAt: startTime,
      sleepStages: sleepStages,
    );
  }

  double _generateNormalDistribution(double mean, double stdDev, double min, double max) {
    // Box-Muller変換で正規分布を生成
    final u1 = _random.nextDouble();
    final u2 = _random.nextDouble();
    final z0 = sqrt(-2 * log(u1)) * cos(2 * pi * u2);
    final value = mean + stdDev * z0;
    
    // 最小値・最大値でクランプ
    return value.clamp(min, max);
  }

  double _calculateQualityScore(Duration duration) {
    final hours = duration.inHours;
    if (hours >= 7 && hours <= 9) {
      return 85 + _random.nextDouble() * 10; // 85-95
    } else if (hours >= 6 && hours <= 10) {
      return 70 + _random.nextDouble() * 15; // 70-85
    } else if (hours >= 5 && hours <= 11) {
      return 55 + _random.nextDouble() * 15; // 55-70
    } else {
      return 35 + _random.nextDouble() * 15; // 35-50
    }
  }

  int _generateWakeQuality(double qualityScore) {
    // 睡眠品質スコアに基づいて目覚めの質を決定（1-5段階）
    // 高い品質ほど良い目覚めになりやすくするが、一定のランダム性も保持
    final baseQuality = (qualityScore / 20).round(); // 80% -> 4, 60% -> 3 など
    final randomOffset = _random.nextInt(3) - 1; // -1, 0, 1のランダム調整
    
    final wakeQuality = baseQuality + randomOffset;
    
    // 1-5の範囲に制限
    return wakeQuality.clamp(1, 5);
  }

  List<MovementData> _generateMovements(DateTime startTime, Duration duration) {
    final movements = <MovementData>[];
    final movementCount = 5 + _random.nextInt(15); // 5-20回の動き
    
    for (int i = 0; i < movementCount; i++) {
      final offset = Duration(
        milliseconds: _random.nextInt(duration.inMilliseconds),
      );
      final timestamp = startTime.add(offset);
      final intensity = _random.nextDouble() * 10; // 0-10の強度
      
      movements.add(MovementData(
        timestamp: timestamp,
        intensity: intensity,
      ));
    }
    
    // 時刻順にソート
    movements.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return movements;
  }

  SleepStageData _generateSleepStages() {
    // 典型的な睡眠ステージの分布を生成
    final deepSleep = 15 + _random.nextDouble() * 10; // 15-25%
    final remSleep = 20 + _random.nextDouble() * 10;  // 20-30%
    final awake = 2 + _random.nextDouble() * 6;       // 2-8%
    final lightSleep = 100 - deepSleep - remSleep - awake; // 残り
    
    final movementCount = 5 + _random.nextInt(15); // 5-20回
    
    return SleepStageData(
      deepSleepPercentage: deepSleep,
      lightSleepPercentage: lightSleep,
      remSleepPercentage: remSleep,
      awakePercentage: awake,
      movementCount: movementCount,
    );
  }
}