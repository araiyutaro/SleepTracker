import 'package:flutter/material.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/usecases/start_sleep_tracking_usecase.dart';
import '../../domain/usecases/end_sleep_tracking_usecase.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../../services/sensor_service.dart';
import '../../services/permission_service.dart';
import '../../services/analytics_service.dart';
import '../../services/health_service.dart';
import 'user_provider.dart';

enum SleepTrackingState {
  idle,
  tracking,
  loading,
  error,
}

class SleepProvider extends ChangeNotifier {
  final StartSleepTrackingUseCase _startSleepTracking;
  final EndSleepTrackingUseCase _endSleepTracking;
  final SleepRepository _sleepRepository;
  final SensorService _sensorService = SensorService();
  final PermissionService _permissionService = PermissionService();
  final HealthService _healthService = HealthService();
  UserProvider? _userProvider;

  SleepProvider({
    required StartSleepTrackingUseCase startSleepTracking,
    required EndSleepTrackingUseCase endSleepTracking,
    required SleepRepository sleepRepository,
  })  : _startSleepTracking = startSleepTracking,
        _endSleepTracking = endSleepTracking,
        _sleepRepository = sleepRepository {
    _initialize();
  }

  void setUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  SleepTrackingState _state = SleepTrackingState.idle;
  SleepSession? _currentSession;
  List<SleepSession> _recentSessions = [];
  String? _errorMessage;
  Duration _currentDuration = Duration.zero;

  SleepTrackingState get state => _state;
  SleepSession? get currentSession => _currentSession;
  List<SleepSession> get recentSessions => _recentSessions;
  String? get errorMessage => _errorMessage;
  Duration get currentDuration => _currentDuration;
  bool get isTracking => _state == SleepTrackingState.tracking;
  SleepRepository get sleepRepository => _sleepRepository;

  Future<void> _initialize() async {
    await checkActiveSession();
    await loadRecentSessions();
    
    // ヘルスサービス初期化
    try {
      await _healthService.initialize();
      debugPrint('HealthService initialized successfully');
    } catch (e) {
      debugPrint('HealthService initialization failed: $e');
    }
  }

  Future<void> checkActiveSession() async {
    try {
      _state = SleepTrackingState.loading;
      notifyListeners();

      _currentSession = await _sleepRepository.getActiveSession();
      if (_currentSession != null) {
        _state = SleepTrackingState.tracking;
        _startDurationTimer();
      } else {
        _state = SleepTrackingState.idle;
      }
    } catch (e) {
      _state = SleepTrackingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> startTracking() async {
    try {
      _state = SleepTrackingState.loading;
      _errorMessage = null;
      notifyListeners();

      _currentSession = await _startSleepTracking.execute();
      _state = SleepTrackingState.tracking;
      _startDurationTimer();
      
      // Analytics: 睡眠記録開始イベント
      await AnalyticsService().logSleepRecordStarted();
      
      try {
        await _sensorService.startMonitoring();
      } catch (e) {
        debugPrint('Failed to start sensor monitoring: $e');
        // センサー監視の開始に失敗してもトラッキングは継続
      }
    } catch (e) {
      _state = SleepTrackingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> stopTracking() async {
    try {
      _state = SleepTrackingState.loading;
      _errorMessage = null;
      notifyListeners();

      try {
        await _sensorService.stopMonitoring();
      } catch (e) {
        debugPrint('Failed to stop sensor monitoring: $e');
      }
      
      // センサー分析データの準備（データベース更新は後でendSessionで一度だけ行う）
      if (_currentSession != null) {
        try {
          final movements = _sensorService.getMovementsForPeriod(
            _currentSession!.startTime,
            DateTime.now(),
          );
          
          final analysisResult = _sensorService.analyzeSleepSession(
            movements,
            DateTime.now().difference(_currentSession!.startTime),
          );
          
          // メモリ上で更新されたセッションを作成（まだDBには保存しない）
          _currentSession = _currentSession!.copyWith(
            movements: movements,
            sleepStages: SleepStageData(
              deepSleepPercentage: analysisResult.deepSleepPercentage,
              lightSleepPercentage: analysisResult.lightSleepPercentage,
              remSleepPercentage: analysisResult.remSleepPercentage,
              awakePercentage: analysisResult.awakePercentage,
              movementCount: analysisResult.movementCount,
            ),
          );
        } catch (e) {
          debugPrint('Failed to analyze sleep session: $e');
          // 分析に失敗してもセッション終了は継続
        }
      }

      debugPrint('Attempting to end sleep session with ID: ${_currentSession?.id}');
      final endedSession = await _endSleepTracking.execute();
      debugPrint('Sleep session ended successfully: ${endedSession.id}');
      
      // Analytics: 睡眠記録完了イベント
      if (endedSession != null) {
        await AnalyticsService().logSleepRecordCompleted(
          durationMinutes: endedSession.duration?.inMinutes ?? 0,
          qualityScore: endedSession.qualityScore,
        );
      }
      
      if (endedSession != null && _userProvider != null) {
        try {
          await _userProvider!.showSleepQualityNotification(
            qualityScore: endedSession.qualityScore ?? 0.0,
            sleepDuration: endedSession.duration ?? Duration.zero,
          );
        } catch (e) {
          debugPrint('Failed to show notification: $e');
        }
      }
      
      // ヘルスデータに書き込み
      if (endedSession != null) {
        await _writeToHealthKit(endedSession);
      }
      
      _currentSession = null;
      _state = SleepTrackingState.idle;
      _currentDuration = Duration.zero;
      
      await loadRecentSessions();
    } catch (e) {
      _state = SleepTrackingState.error;
      _errorMessage = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> loadRecentSessions() async {
    try {
      _recentSessions = await _sleepRepository.getSessions(limit: 7);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recent sessions: $e');
    }
  }

  /// ヘルスキットに睡眠データを書き込み
  Future<void> _writeToHealthKit(SleepSession session) async {
    try {
      if (!_healthService.isInitialized) {
        debugPrint('HealthService not initialized, skipping HealthKit write');
        return;
      }

      // 権限確認
      bool hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        debugPrint('No HealthKit permissions, requesting...');
        bool granted = await _healthService.requestPermissions();
        if (!granted) {
          debugPrint('HealthKit permissions denied - this may affect data sync');
          // 権限がなくても睡眠記録は継続できるようにする
          return;
        } else {
          debugPrint('HealthKit permissions granted successfully');
        }
      } else {
        debugPrint('HealthKit permissions already granted');
      }

      DateTime bedTime = session.startTime;
      DateTime? wakeTime = session.endTime;
      
      if (wakeTime == null) {
        debugPrint('Session end time is null, cannot write to HealthKit');
        return;
      }

      // 睡眠ステージデータの準備
      Duration? deepSleepDuration;
      Duration? lightSleepDuration;
      Duration? remSleepDuration;

      if (session.sleepStages != null) {
        // 睡眠ステージデータがある場合
        var stages = session.sleepStages!;
        Duration totalSleep = wakeTime.difference(bedTime);
        deepSleepDuration = Duration(minutes: (totalSleep.inMinutes * stages.deepSleepPercentage / 100).round());
        lightSleepDuration = Duration(minutes: (totalSleep.inMinutes * stages.lightSleepPercentage / 100).round());
        remSleepDuration = Duration(minutes: (totalSleep.inMinutes * stages.remSleepPercentage / 100).round());
      } else {
        // 睡眠ステージデータがない場合、推定値を使用
        Duration totalSleep = wakeTime.difference(bedTime);
        deepSleepDuration = Duration(minutes: (totalSleep.inMinutes * 0.25).round());
        lightSleepDuration = Duration(minutes: (totalSleep.inMinutes * 0.55).round());
        remSleepDuration = Duration(minutes: (totalSleep.inMinutes * 0.20).round());
      }

      // ヘルスキットに書き込み
      bool success = await _healthService.writeSleepStagesData(
        bedTime: bedTime,
        wakeTime: wakeTime,
        deepSleepDuration: deepSleepDuration,
        lightSleepDuration: lightSleepDuration,
        remSleepDuration: remSleepDuration,
      );

      if (success) {
        debugPrint('Successfully wrote sleep data to HealthKit');
        // Analyticsイベント送信
        await AnalyticsService().logCustomEvent('health_data_exported', parameters: {
          'platform': 'healthkit',
          'data_type': 'sleep',
          'duration_minutes': session.duration?.inMinutes ?? 0,
        });
      } else {
        debugPrint('Failed to write sleep data to HealthKit');
      }
    } catch (e) {
      debugPrint('Error writing to HealthKit: $e');
    }
  }


  /// ヘルスキット権限要求
  Future<bool> requestHealthPermissions() async {
    try {
      if (!_healthService.isInitialized) {
        debugPrint('Initializing HealthService...');
        await _healthService.initialize();
      }
      
      bool isSupported = await _healthService.isSupported();
      if (!isSupported) {
        debugPrint('Health data not supported on this platform');
        return false;
      }

      debugPrint('Platform supports health data, requesting permissions...');
      bool granted = await _healthService.requestPermissions();
      
      if (granted) {
        debugPrint('Health permissions granted successfully');
      } else {
        debugPrint('Health permissions denied by user');
      }
      
      return granted;
    } catch (e, stackTrace) {
      debugPrint('Error requesting health permissions: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// ヘルスキットから睡眠データを読み取り
  Future<Map<String, dynamic>> getHealthSummary({int days = 7}) async {
    try {
      if (!_healthService.isInitialized) {
        await _healthService.initialize();
      }

      bool hasPermissions = await _healthService.hasPermissions();
      if (!hasPermissions) {
        debugPrint('No health permissions for reading data');
        return {};
      }

      DateTime now = DateTime.now();
      DateTime fromDate = now.subtract(Duration(days: days));

      return await _healthService.getTodayHealthSummary();
    } catch (e) {
      debugPrint('Error getting health summary: $e');
      return {};
    }
  }

  void _startDurationTimer() {
    if (_currentSession == null) return;
    
    Future.doWhile(() async {
      if (_state != SleepTrackingState.tracking || _currentSession == null) {
        return false;
      }
      
      _currentDuration = DateTime.now().difference(_currentSession!.startTime);
      notifyListeners();
      
      await Future.delayed(const Duration(seconds: 1));
      return true;
    });
  }

  String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<bool> requestSensorPermissions(BuildContext context) async {
    try {
      return await _permissionService.handlePermissions(context);
    } catch (e) {
      debugPrint('Failed to request sensor permissions: $e');
      return false;
    }
  }

  Future<void> deleteSession(String sessionId) async {
    try {
      debugPrint('Deleting sleep session: $sessionId');
      await _sleepRepository.deleteSession(sessionId);
      debugPrint('Sleep session deleted successfully');
      
      await loadRecentSessions();
    } catch (e) {
      debugPrint('Failed to delete sleep session: $e');
      _errorMessage = 'セッションの削除に失敗しました: $e';
      notifyListeners();
    }
  }
}