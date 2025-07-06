import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../domain/entities/sleep_session.dart';

class SensorService {
  static final SensorService _instance = SensorService._internal();
  factory SensorService() => _instance;
  SensorService._internal();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final List<MovementData> _movementBuffer = [];
  Timer? _analysisTimer;
  
  static const double _movementThreshold = 2.0;
  static const Duration _bufferDuration = Duration(seconds: 30);
  static const Duration _analysisInterval = Duration(minutes: 5);

  List<MovementData> get recentMovements => List.unmodifiable(_movementBuffer);

  Future<void> startMonitoring() async {
    await stopMonitoring();
    
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      final magnitude = _calculateMagnitude(event);
      if (magnitude > _movementThreshold) {
        final movement = MovementData(
          timestamp: DateTime.now(),
          intensity: magnitude,
        );
        _movementBuffer.add(movement);
        _cleanOldMovements();
      }
    });

    _analysisTimer = Timer.periodic(_analysisInterval, (_) {
      _performAnalysis();
    });
    
    debugPrint('Sensor monitoring started');
  }

  Future<void> stopMonitoring() async {
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _analysisTimer?.cancel();
    _analysisTimer = null;
    _movementBuffer.clear();
    debugPrint('Sensor monitoring stopped');
  }

  double _calculateMagnitude(AccelerometerEvent event) {
    return sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  }

  void _cleanOldMovements() {
    final cutoffTime = DateTime.now().subtract(_bufferDuration);
    _movementBuffer.removeWhere((movement) => movement.timestamp.isBefore(cutoffTime));
  }

  void _performAnalysis() {
    if (_movementBuffer.isEmpty) return;
    
    final now = DateTime.now();
    final recentMovements = _movementBuffer.where(
      (m) => m.timestamp.isAfter(now.subtract(_analysisInterval)),
    ).toList();
    
    if (recentMovements.isNotEmpty) {
      final averageIntensity = recentMovements.fold<double>(
        0,
        (sum, m) => sum + m.intensity,
      ) / recentMovements.length;
      
      debugPrint('Analysis: ${recentMovements.length} movements, avg intensity: ${averageIntensity.toStringAsFixed(2)}');
    }
  }

  SleepAnalysisResult analyzeSleepSession(List<MovementData> movements, Duration duration) {
    if (movements.isEmpty) {
      return SleepAnalysisResult(
        qualityScore: 85.0,
        deepSleepPercentage: 20.0,
        lightSleepPercentage: 55.0,
        remSleepPercentage: 25.0,
        awakePercentage: 0.0,
        movementCount: 0,
      );
    }

    final movementCount = movements.length;
    final hourlyMovement = movementCount / (duration.inHours + 1);
    
    double qualityScore = 100.0;
    if (hourlyMovement > 20) {
      qualityScore = 40.0;
    } else if (hourlyMovement > 15) {
      qualityScore = 60.0;
    } else if (hourlyMovement > 10) {
      qualityScore = 75.0;
    } else if (hourlyMovement > 5) {
      qualityScore = 85.0;
    }

    final averageIntensity = movements.fold<double>(
      0,
      (sum, m) => sum + m.intensity,
    ) / movements.length;

    if (averageIntensity > 5.0) {
      qualityScore *= 0.8;
    }

    final deepSleep = max(10.0, min(30.0, 25.0 - hourlyMovement));
    final remSleep = max(15.0, min(30.0, 25.0 - hourlyMovement * 0.5));
    final awake = min(10.0, hourlyMovement * 0.5);
    final lightSleep = 100.0 - deepSleep - remSleep - awake;

    return SleepAnalysisResult(
      qualityScore: qualityScore,
      deepSleepPercentage: deepSleep,
      lightSleepPercentage: lightSleep,
      remSleepPercentage: remSleep,
      awakePercentage: awake,
      movementCount: movementCount,
    );
  }

  List<MovementData> getMovementsForPeriod(DateTime start, DateTime end) {
    return _movementBuffer.where((movement) {
      return movement.timestamp.isAfter(start) && movement.timestamp.isBefore(end);
    }).toList();
  }
}

class SleepAnalysisResult {
  final double qualityScore;
  final double deepSleepPercentage;
  final double lightSleepPercentage;
  final double remSleepPercentage;
  final double awakePercentage;
  final int movementCount;

  SleepAnalysisResult({
    required this.qualityScore,
    required this.deepSleepPercentage,
    required this.lightSleepPercentage,
    required this.remSleepPercentage,
    required this.awakePercentage,
    required this.movementCount,
  });
}