import 'package:flutter/material.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/usecases/start_sleep_tracking_usecase.dart';
import '../../domain/usecases/end_sleep_tracking_usecase.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../../services/sensor_service.dart';
import '../../services/permission_service.dart';
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
}