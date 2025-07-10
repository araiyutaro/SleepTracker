import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _initialized = false;

  FirebaseAnalytics? get analytics => _analytics;
  FirebaseAnalyticsObserver? get observer => _observer;
  bool get isInitialized => _initialized;

  void initialize() {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      _initialized = true;
    } catch (e) {
      debugPrint('Analytics: Failed to initialize: $e');
      _analytics = null;
      _observer = null;
      _initialized = false;
    }
  }

  void initializeStub() {
    _analytics = null;
    _observer = null;
    _initialized = false;
    debugPrint('Analytics: Initialized in stub mode');
  }

  // ユーザープロパティの設定
  Future<void> setUserProperties({
    String? userId,
    String? ageGroup,
    String? gender,
    String? occupation,
  }) async {
    if (!_initialized || _analytics == null) {
      debugPrint('Analytics: User properties skipped (not initialized)');
      return;
    }
    
    try {
      if (userId != null) {
        await _analytics!.setUserId(id: userId);
      }
      
      if (ageGroup != null) {
        await _analytics!.setUserProperty(name: 'age_group', value: ageGroup);
      }
      
      if (gender != null) {
        await _analytics!.setUserProperty(name: 'gender', value: gender);
      }
      
      if (occupation != null) {
        await _analytics!.setUserProperty(name: 'occupation', value: occupation);
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
    if (!_initialized || _analytics == null) {
      debugPrint('Analytics: Screen view skipped (not initialized): $screenName');
      return;
    }
    
    try {
      await _analytics!.logScreenView(screenName: screenName);
      debugPrint('Analytics: Screen view logged: $screenName');
    } catch (e) {
      debugPrint('Analytics: Error logging screen view $screenName: $e');
    }
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
    if (!_initialized || _analytics == null) {
      debugPrint('Analytics: Event skipped (not initialized): $eventName');
      return;
    }
    
    try {
      await _analytics!.logEvent(
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
    if (!_initialized || _analytics == null) {
      debugPrint('Analytics: Collection setting skipped (not initialized)');
      return;
    }
    
    try {
      await _analytics!.setAnalyticsCollectionEnabled(enabled);
      debugPrint('Analytics: Collection enabled: $enabled');
    } catch (e) {
      debugPrint('Analytics: Error setting collection enabled: $e');
    }
  }

  // アプリの初回起動イベント
  Future<void> logFirstOpen() async {
    if (!_initialized || _analytics == null) {
      debugPrint('Analytics: First open skipped (not initialized)');
      return;
    }
    
    try {
      await _analytics!.logAppOpen();
      debugPrint('Analytics: First open logged');
    } catch (e) {
      debugPrint('Analytics: Error logging first open: $e');
    }
  }
}