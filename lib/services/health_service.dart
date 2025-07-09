import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  late final HealthFactory _health;
  bool _isInitialized = false;

  /// ヘルスサービス初期化
  Future<void> initialize() async {
    try {
      _health = HealthFactory();
      _isInitialized = true;
      debugPrint('HealthService: Initialized successfully');
    } catch (e) {
      debugPrint('HealthService: Initialization failed: $e');
    }
  }

  /// 権限要求
  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final types = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      
      debugPrint('HealthService: Requesting permissions for ${types.length} health data types');
      
      // プラットフォームサポート確認
      bool isSupported = await _health.isDataTypeAvailable(HealthDataType.SLEEP_ASLEEP);
      debugPrint('HealthService: Sleep data type availability: $isSupported');
      
      if (!isSupported) {
        debugPrint('HealthService: Health data types not supported on this platform');
        return false;
      }
      
      bool requested = await _health.requestAuthorization(types);
      debugPrint('HealthService: Permission request result: $requested');
      
      // 各権限の詳細確認
      for (final type in types) {
        bool? hasPermission = await _health.hasPermissions([type]);
        debugPrint('HealthService: Permission for $type: $hasPermission');
      }
      
      return requested;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Permission request failed: $e');
      debugPrint('HealthService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 権限確認
  Future<bool> hasPermissions() async {
    if (!_isInitialized) {
      debugPrint('HealthService: Service not initialized');
      return false;
    }

    try {
      final types = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];
      
      debugPrint('HealthService: Checking permissions for ${types.length} health data types');
      
      bool? hasPermissions = await _health.hasPermissions(types);
      debugPrint('HealthService: Has permissions result: $hasPermissions');
      
      // 各権限の詳細確認
      for (final type in types) {
        bool? hasPermission = await _health.hasPermissions([type]);
        debugPrint('HealthService: Has permission for $type: $hasPermission');
      }
      
      return hasPermissions ?? false;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Permission check failed: $e');
      debugPrint('HealthService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 睡眠データを書き込み
  Future<bool> writeSleepData({
    required DateTime bedTime,
    required DateTime wakeTime,
    HealthDataType type = HealthDataType.SLEEP_ASLEEP,
  }) async {
    if (!_isInitialized) return false;

    try {
      bool success = await _health.writeHealthData(
        0, // 睡眠の場合、値は使用されない
        type,
        bedTime,
        wakeTime,
      );

      debugPrint('HealthService: Sleep data write result: $success');
      return success;
    } catch (e) {
      debugPrint('HealthService: Failed to write sleep data: $e');
      return false;
    }
  }

  /// 複数の睡眠ステージデータを書き込み
  Future<bool> writeSleepStagesData({
    required DateTime bedTime,
    required DateTime wakeTime,
    Duration? deepSleepDuration,
    Duration? lightSleepDuration,
    Duration? remSleepDuration,
    Duration? awakeDuration,
  }) async {
    if (!_isInitialized) return false;

    try {
      List<Future<bool>> writes = [];

      // メインの睡眠時間
      writes.add(writeSleepData(
        bedTime: bedTime,
        wakeTime: wakeTime,
        type: HealthDataType.SLEEP_ASLEEP,
      ));

      // ベッドタイム
      writes.add(writeSleepData(
        bedTime: bedTime,
        wakeTime: wakeTime,
        type: HealthDataType.SLEEP_IN_BED,
      ));

      // 深い睡眠
      if (deepSleepDuration != null) {
        DateTime deepStart = bedTime;
        DateTime deepEnd = deepStart.add(deepSleepDuration);
        writes.add(writeSleepData(
          bedTime: deepStart,
          wakeTime: deepEnd,
          type: HealthDataType.SLEEP_DEEP,
        ));
      }

      // 浅い睡眠
      if (lightSleepDuration != null) {
        DateTime lightStart = bedTime.add(deepSleepDuration ?? Duration.zero);
        DateTime lightEnd = lightStart.add(lightSleepDuration);
        writes.add(writeSleepData(
          bedTime: lightStart,
          wakeTime: lightEnd,
          type: HealthDataType.SLEEP_LIGHT,
        ));
      }

      // REM睡眠
      if (remSleepDuration != null) {
        Duration previousDuration = (deepSleepDuration ?? Duration.zero) + 
                                  (lightSleepDuration ?? Duration.zero);
        DateTime remStart = bedTime.add(previousDuration);
        DateTime remEnd = remStart.add(remSleepDuration);
        writes.add(writeSleepData(
          bedTime: remStart,
          wakeTime: remEnd,
          type: HealthDataType.SLEEP_REM,
        ));
      }

      List<bool> results = await Future.wait(writes);
      bool allSuccess = results.every((result) => result);

      debugPrint('HealthService: Sleep stages write result: $allSuccess');
      return allSuccess;
    } catch (e) {
      debugPrint('HealthService: Failed to write sleep stages data: $e');
      return false;
    }
  }

  /// 今日のヘルスサマリーを取得
  Future<Map<String, dynamic>> getTodayHealthSummary() async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // 基本的な空のデータを返す（実際の実装では各種データを取得）
      return {
        'sleepData': <HealthDataPoint>[],
        'heartRateData': <HealthDataPoint>[],
        'stepsData': <HealthDataPoint>[],
        'caloriesData': <HealthDataPoint>[],
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      debugPrint('HealthService: Failed to get today health summary: $e');
      return {
        'sleepData': <HealthDataPoint>[],
        'heartRateData': <HealthDataPoint>[],
        'stepsData': <HealthDataPoint>[],
        'caloriesData': <HealthDataPoint>[],
        'lastUpdated': DateTime.now(),
      };
    }
  }

  /// プラットフォームサポート確認
  Future<bool> isSupported() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      
      // 基本的な睡眠データタイプがサポートされているか確認
      bool sleepSupported = await _health.isDataTypeAvailable(HealthDataType.SLEEP_ASLEEP);
      debugPrint('HealthService: Sleep data type supported: $sleepSupported');
      
      return sleepSupported;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Platform support check failed: $e');
      debugPrint('HealthService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 初期化状態確認
  bool get isInitialized => _isInitialized;
}