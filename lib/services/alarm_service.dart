import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import '../domain/entities/sleep_session.dart';
import '../domain/repositories/sleep_repository.dart';

class AlarmService {
  final SleepRepository _sleepRepository;
  final FlutterLocalNotificationsPlugin _notifications;
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  List<double> _recentMovements = [];
  Timer? _alarmCheckTimer;
  
  static const int _movementWindowMinutes = 30;
  static const double _lightSleepThreshold = 0.5;
  static const double _movementSensitivity = 0.3;

  AlarmService({
    required SleepRepository sleepRepository,
    required FlutterLocalNotificationsPlugin notifications,
  })  : _sleepRepository = sleepRepository,
        _notifications = notifications;

  Future<void> scheduleSmartAlarm({
    required TimeOfDay targetWakeTime,
    required int windowMinutes,
  }) async {
    final now = DateTime.now();
    final targetDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      targetWakeTime.hour,
      targetWakeTime.minute,
    );
    
    DateTime actualTarget = targetDateTime;
    if (actualTarget.isBefore(now)) {
      actualTarget = actualTarget.add(const Duration(days: 1));
    }
    
    final windowStart = actualTarget.subtract(Duration(minutes: windowMinutes));
    
    if (windowStart.isAfter(now)) {
      final delayUntilWindow = windowStart.difference(now);
      Timer(delayUntilWindow, () {
        _startOptimalWakeDetection(actualTarget, windowMinutes);
      });
    } else {
      _startOptimalWakeDetection(actualTarget, windowMinutes);
    }
    
    await _scheduleBackupAlarm(actualTarget);
  }

  void _startOptimalWakeDetection(DateTime targetTime, int windowMinutes) {
    _recentMovements.clear();
    
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final movementIntensity = _calculateMovementIntensity(event);
      _recentMovements.add(movementIntensity);
      
      if (_recentMovements.length > _movementWindowMinutes) {
        _recentMovements.removeAt(0);
      }
    });
    
    _alarmCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      
      if (now.isAfter(targetTime)) {
        _triggerAlarm('定時アラーム', '目標起床時刻です');
        _stopOptimalWakeDetection();
        return;
      }
      
      if (_isInLightSleepPhase()) {
        final remainingTime = targetTime.difference(now).inMinutes;
        if (remainingTime <= 10) {
          _triggerAlarm('スマートアラーム', '浅い睡眠を検出しました。起床に最適なタイミングです');
          _stopOptimalWakeDetection();
          return;
        }
      }
    });
  }

  bool _isInLightSleepPhase() {
    if (_recentMovements.length < _movementWindowMinutes ~/ 2) {
      return false;
    }
    
    final recentAverage = _recentMovements
        .skip(_recentMovements.length - 10)
        .reduce((a, b) => a + b) / 10;
    
    return recentAverage > _lightSleepThreshold;
  }

  double _calculateMovementIntensity(AccelerometerEvent event) {
    final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final baseline = 9.8;
    return max(0.0, (magnitude - baseline).abs() / baseline);
  }

  Future<void> _scheduleBackupAlarm(DateTime targetTime) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_alarm_channel',
      'スマートアラーム',
      channelDescription: '睡眠サイクルに基づくスマートアラーム',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      999,
      'アラーム',
      '目標起床時刻です',
      tz.TZDateTime.from(targetTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _triggerAlarm(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'smart_alarm_channel',
      'スマートアラーム',
      channelDescription: '睡眠サイクルに基づくスマートアラーム',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm_sound'),
      playSound: true,
      ongoing: true,
      autoCancel: false,
    );

    const iosDetails = DarwinNotificationDetails(
      sound: 'alarm_sound.aiff',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      998,
      title,
      body,
      details,
    );
  }

  void _stopOptimalWakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _alarmCheckTimer?.cancel();
    _alarmCheckTimer = null;
    _recentMovements.clear();
  }

  Future<void> cancelAlarm() async {
    await _notifications.cancel(998);
    await _notifications.cancel(999);
    _stopOptimalWakeDetection();
  }

  Future<TimeOfDay?> calculateOptimalBedtime(TimeOfDay wakeTime, {int sleepCycles = 5}) async {
    const cycleMinutes = 90;
    final totalSleepMinutes = sleepCycles * cycleMinutes;
    const fallAsleepMinutes = 15;
    
    final wakeDateTime = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      wakeTime.hour,
      wakeTime.minute,
    );
    
    final bedtime = wakeDateTime.subtract(
      Duration(minutes: totalSleepMinutes + fallAsleepMinutes),
    );
    
    return TimeOfDay.fromDateTime(bedtime);
  }

  Future<List<TimeOfDay>> getSuggestedBedtimes(TimeOfDay wakeTime) async {
    final suggestions = <TimeOfDay>[];
    
    for (int cycles = 4; cycles <= 6; cycles++) {
      final bedtime = await calculateOptimalBedtime(wakeTime, sleepCycles: cycles);
      if (bedtime != null) {
        suggestions.add(bedtime);
      }
    }
    
    return suggestions;
  }

  void dispose() {
    _stopOptimalWakeDetection();
  }
}