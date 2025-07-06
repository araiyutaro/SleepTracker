import 'package:flutter/material.dart';
import '../../domain/entities/sleep_session.dart';
import '../../domain/usecases/start_sleep_tracking_usecase.dart';
import '../../domain/usecases/end_sleep_tracking_usecase.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../../services/sensor_service.dart';
import '../../services/permission_service.dart';

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

  SleepProvider({
    required StartSleepTrackingUseCase startSleepTracking,
    required EndSleepTrackingUseCase endSleepTracking,
    required SleepRepository sleepRepository,
  })  : _startSleepTracking = startSleepTracking,
        _endSleepTracking = endSleepTracking,
        _sleepRepository = sleepRepository {
    _initialize();
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
      
      await _sensorService.startMonitoring();
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

      await _sensorService.stopMonitoring();
      
      if (_currentSession != null) {
        final movements = _sensorService.getMovementsForPeriod(
          _currentSession!.startTime,
          DateTime.now(),
        );
        
        final analysisResult = _sensorService.analyzeSleepSession(
          movements,
          DateTime.now().difference(_currentSession!.startTime),
        );
        
        final updatedSession = _currentSession!.copyWith(
          movements: movements,
          sleepStages: SleepStageData(
            deepSleepPercentage: analysisResult.deepSleepPercentage,
            lightSleepPercentage: analysisResult.lightSleepPercentage,
            remSleepPercentage: analysisResult.remSleepPercentage,
            awakePercentage: analysisResult.awakePercentage,
            movementCount: analysisResult.movementCount,
          ),
        );
        
        await _sleepRepository.updateSession(updatedSession);
      }

      final endedSession = await _endSleepTracking.execute();
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
    return await _permissionService.handlePermissions(context);
  }
}