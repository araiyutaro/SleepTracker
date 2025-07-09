import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;

  void initialize() {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ユーザープロパティの設定
  Future<void> setUserProperties({
    String? userId,
    String? ageGroup,
    String? gender,
    String? occupation,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      
      if (ageGroup != null) {
        await _analytics.setUserProperty(name: 'age_group', value: ageGroup);
      }
      
      if (gender != null) {
        await _analytics.setUserProperty(name: 'gender', value: gender);
      }
      
      if (occupation != null) {
        await _analytics.setUserProperty(name: 'occupation', value: occupation);
      }
      
      debugPrint('Analytics: User properties set');
    } catch (e) {
      debugPrint('Analytics: Error setting user properties: $e');
    }
  }

  // オンボーディング関連イベント
  Future<void> logOnboardingStarted() async {
    await _logEvent('onboarding_started');
  }

  Future<void> logOnboardingCompleted({
    String? ageGroup,
    String? gender,
    String? occupation,
  }) async {
    await _logEvent('onboarding_completed', parameters: {
      if (ageGroup != null) 'age_group': ageGroup,
      if (gender != null) 'gender': gender,
      if (occupation != null) 'occupation': occupation,
    });
  }

  Future<void> logOnboardingStepCompleted(String stepName) async {
    await _logEvent('onboarding_step_completed', parameters: {
      'step_name': stepName,
    });
  }

  // 睡眠記録関連イベント
  Future<void> logSleepRecordStarted() async {
    await _logEvent('sleep_record_started');
  }

  Future<void> logSleepRecordCompleted({
    required int durationMinutes,
    double? qualityScore,
  }) async {
    await _logEvent('sleep_record_completed', parameters: {
      'duration_minutes': durationMinutes,
      if (qualityScore != null) 'quality_score': qualityScore,
    });
  }

  Future<void> logSleepDataExported(String format) async {
    await _logEvent('sleep_data_exported', parameters: {
      'export_format': format,
    });
  }

  // 設定関連イベント
  Future<void> logSettingsChanged(String settingName, dynamic value) async {
    await _logEvent('settings_changed', parameters: {
      'setting_name': settingName,
      'setting_value': value.toString(),
    });
  }

  Future<void> logNotificationSettingsChanged({
    required bool bedtimeReminderEnabled,
    required bool wakeUpAlarmEnabled,
  }) async {
    await _logEvent('notification_settings_changed', parameters: {
      'bedtime_reminder_enabled': bedtimeReminderEnabled,
      'wake_up_alarm_enabled': wakeUpAlarmEnabled,
    });
  }

  // アプリ使用状況イベント
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    debugPrint('Analytics: Screen view logged: $screenName');
  }

  Future<void> logAppOpened() async {
    await _logEvent('app_opened');
  }

  Future<void> logFeatureUsed(String featureName) async {
    await _logEvent('feature_used', parameters: {
      'feature_name': featureName,
    });
  }

  // エラー・クラッシュ関連
  Future<void> logError(String errorName, String errorMessage) async {
    await _logEvent('app_error', parameters: {
      'error_name': errorName,
      'error_message': errorMessage,
    });
  }

  // カスタムイベント
  Future<void> logCustomEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    await _logEvent(eventName, parameters: parameters);
  }

  // プライベートヘルパーメソッド
  Future<void> _logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint('Analytics: Event logged: $eventName${parameters != null ? ' with parameters: $parameters' : ''}');
    } catch (e) {
      debugPrint('Analytics: Error logging event $eventName: $e');
    }
  }

  // デバッグ情報
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
    debugPrint('Analytics: Collection enabled: $enabled');
  }

  // アプリの初回起動イベント
  Future<void> logFirstOpen() async {
    await _analytics.logAppOpen();
  }
}