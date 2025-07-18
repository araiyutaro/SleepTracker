import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // アラームサービスから使用するためのgetter
  FlutterLocalNotificationsPlugin get flutterLocalNotificationsPlugin => _notifications;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      debugPrint('Notification tapped with payload: $payload');
    }
  }

  Future<bool> requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    bool granted = true;

    if (android != null) {
      granted = await android.requestNotificationsPermission() ?? false;
    }

    if (ios != null) {
      granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      ) ?? false;
    }

    return granted;
  }

  Future<void> scheduleBedtimeReminder({
    required TimeOfDay bedtime,
    required int reminderMinutes,
  }) async {
    await _notifications.cancel(1); // Cancel existing bedtime reminder

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      bedtime.hour,
      bedtime.minute,
    ).subtract(Duration(minutes: reminderMinutes));

    // If the time has passed today, schedule for tomorrow
    final finalTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await _notifications.zonedSchedule(
      1,
      '睡眠の時間です',
      'そろそろ寝る準備をしましょう。良い睡眠を！',
      tz.TZDateTime.from(finalTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'bedtime_reminder',
          '就寝リマインダー',
          channelDescription: '就寝時刻の前にお知らせします',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bedtime_reminder',
    );
  }

  Future<void> scheduleWakeUpAlarm({
    required TimeOfDay wakeTime,
    required bool enabled,
  }) async {
    await _notifications.cancel(2); // Cancel existing wake-up alarm

    if (!enabled) return;

    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      wakeTime.hour,
      wakeTime.minute,
    );

    // If the time has passed today, schedule for tomorrow
    final finalTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await _notifications.zonedSchedule(
      2,
      'おはようございます！',
      '素晴らしい1日の始まりです。起床時刻になりました。',
      tz.TZDateTime.from(finalTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wake_up_alarm',
          '起床アラーム',
          channelDescription: '設定した時刻にお知らせします',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@drawable/ic_notification',
          sound: RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.wav',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'wake_up_alarm',
    );
  }

  Future<void> showSleepQualityNotification({
    required double qualityScore,
    required Duration sleepDuration,
  }) async {
    String title;
    String body;

    if (qualityScore >= 90) {
      title = '素晴らしい睡眠でした！';
      body = '品質スコア: ${qualityScore.toInt()}% - 完璧な睡眠です';
    } else if (qualityScore >= 80) {
      title = '良い睡眠でした';
      body = '品質スコア: ${qualityScore.toInt()}% - 良質な睡眠でした';
    } else if (qualityScore >= 60) {
      title = '普通の睡眠でした';
      body = '品質スコア: ${qualityScore.toInt()}% - 改善の余地があります';
    } else {
      title = '睡眠の質を改善しましょう';
      body = '品質スコア: ${qualityScore.toInt()}% - より良い睡眠を目指しましょう';
    }

    await _notifications.show(
      3,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_quality',
          '睡眠品質通知',
          channelDescription: '睡眠品質の結果をお知らせします',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'sleep_quality',
    );
  }

  Future<void> scheduleWeeklyReport() async {
    await _notifications.cancel(4); // Cancel existing weekly report

    final now = DateTime.now();
    final nextSunday = now.add(Duration(days: 7 - now.weekday));
    final scheduledTime = DateTime(
      nextSunday.year,
      nextSunday.month,
      nextSunday.day,
      9, // 9 AM
      0,
    );

    await _notifications.zonedSchedule(
      4,
      '週間睡眠レポート',
      'この1週間の睡眠データを確認してみましょう',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_report',
          '週間レポート',
          channelDescription: '週1回の睡眠レポートをお知らせします',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@drawable/ic_notification',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'weekly_report',
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}