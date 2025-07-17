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
    await _logEvent('sleep_record_started', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'source': 'automatic',
    });
  }

  Future<void> logSleepRecordCompleted({
    required int durationMinutes,
    double? qualityScore,
    int? wakeQuality,
    bool hasMovementData = false,
    bool hasSleepStages = false,
  }) async {
    await _logEvent('sleep_record_completed', parameters: {
      'duration_minutes': durationMinutes,
      'duration_hours': (durationMinutes / 60).round(),
      if (qualityScore != null) 'quality_score': qualityScore.round(),
      if (wakeQuality != null) 'wake_quality': wakeQuality,
      'has_movement_data': hasMovementData,
      'has_sleep_stages': hasSleepStages,
      'completion_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logManualSleepRecordAdded({
    required int durationMinutes,
    double? qualityScore,
    int? wakeQuality,
  }) async {
    await _logEvent('manual_sleep_record_added', parameters: {
      'duration_minutes': durationMinutes,
      'duration_hours': (durationMinutes / 60).round(),
      if (qualityScore != null) 'quality_score': qualityScore.round(),
      if (wakeQuality != null) 'wake_quality': wakeQuality,
      'source': 'manual',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logSleepRecordEdited({
    required String sessionId,
    required int durationMinutes,
    double? qualityScore,
    int? wakeQuality,
  }) async {
    await _logEvent('sleep_record_edited', parameters: {
      'session_id': sessionId.substring(0, 8), // 匿名化
      'duration_minutes': durationMinutes,
      'duration_hours': (durationMinutes / 60).round(),
      if (qualityScore != null) 'quality_score': qualityScore.round(),
      if (wakeQuality != null) 'wake_quality': wakeQuality,
      'edit_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logSleepRecordDeleted() async {
    await _logEvent('sleep_record_deleted', parameters: {
      'delete_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logWakeQualityRated(int rating) async {
    await _logEvent('wake_quality_rated', parameters: {
      'rating': rating,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logSleepDataExported(String format) async {
    await _logEvent('sleep_data_exported', parameters: {
      'export_format': format,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logDemoDataGenerated(int recordCount) async {
    await _logEvent('demo_data_generated', parameters: {
      'record_count': recordCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logAllDataCleared() async {
    await _logEvent('all_data_cleared', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logBackupCreated(int recordCount) async {
    await _logEvent('backup_created', parameters: {
      'record_count': recordCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logBackupRestored(int recordCount) async {
    await _logEvent('backup_restored', parameters: {
      'record_count': recordCount,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
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

  // UIインタラクション関連イベント
  Future<void> logButtonTapped(String buttonName, {Map<String, dynamic>? context}) async {
    await _logEvent('button_tapped', parameters: {
      'button_name': buttonName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (context != null) ...context,
    });
  }

  Future<void> logNavigationEvent(String fromScreen, String toScreen) async {
    await _logEvent('navigation', parameters: {
      'from_screen': fromScreen,
      'to_screen': toScreen,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logDialogOpened(String dialogName) async {
    await _logEvent('dialog_opened', parameters: {
      'dialog_name': dialogName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logFeatureUsed(String featureName, {Map<String, dynamic>? metadata}) async {
    await _logEvent('feature_used', parameters: {
      'feature_name': featureName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      if (metadata != null) ...metadata,
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
    await _logEvent('app_opened', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logAppBackgrounded() async {
    await _logEvent('app_backgrounded', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> logAppForegrounded() async {
    await _logEvent('app_foregrounded', parameters: {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
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