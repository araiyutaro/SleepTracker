import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

class HealthService {
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  late final Health _health;
  bool _isInitialized = false;

  /// ヘルスサービス初期化
  Future<void> initialize() async {
    try {
      _health = Health();
      await _health.configure();
      _isInitialized = true;
      debugPrint('HealthService: Initialized successfully');
    } catch (e) {
      debugPrint('HealthService: Initialization failed: $e');
    }
  }

  /// 権限要求（オプション機能）
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) {
        debugPrint('HealthService: Initializing before permission request...');
        await initialize();
      }

      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
      ];

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
      bool isSupported = Health().isDataTypeAvailable(HealthDataType.SLEEP_ASLEEP);
      debugPrint('HealthService: Sleep data type availability: $isSupported');
      
      if (!isSupported) {
        debugPrint('HealthService: Health data types not supported on this platform');
        return false;
      }
      
      debugPrint('HealthService: Requesting authorization from user...');
      bool requested = await _health.requestAuthorization(types, permissions: permissions);
      debugPrint('HealthService: Permission request result: $requested');
      
      // 各権限の詳細確認（エラーが発生しても継続）
      try {
        for (int i = 0; i < types.length; i++) {
          try {
            bool? hasPermission = await _health.hasPermissions([types[i]], permissions: [permissions[i]]);
            debugPrint('HealthService: Permission for ${types[i]}: $hasPermission');
          } catch (e) {
            debugPrint('HealthService: Failed to check permission for ${types[i]}: $e');
          }
        }
      } catch (e) {
        debugPrint('HealthService: Error during permission verification: $e');
      }
      
      return requested;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Permission request failed (アプリは継続します): $e');
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
      final permissions = [
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
        HealthDataAccess.READ_WRITE,
      ];

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
      
      bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
      debugPrint('HealthService: Has permissions result: $hasPermissions');
      
      // 各権限の詳細確認
      for (int i = 0; i < types.length; i++) {
        bool? hasPermission = await _health.hasPermissions([types[i]], permissions: [permissions[i]]);
        debugPrint('HealthService: Has permission for ${types[i]}: $hasPermission');
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
    if (!_isInitialized) {
      debugPrint('HealthService: Not initialized, cannot write sleep data');
      return false;
    }

    try {
      debugPrint('HealthService: Writing sleep data - Type: $type, Bed: $bedTime, Wake: $wakeTime');
      
      bool success = await _health.writeHealthData(
        value: 0, // 睡眠の場合、値は使用されない
        type: type,
        startTime: bedTime,
        endTime: wakeTime,
      );

      debugPrint('HealthService: Sleep data write result: $success');
      return success;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Failed to write sleep data: $e');
      debugPrint('HealthService: Stack trace: $stackTrace');
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
    if (!_isInitialized) {
      debugPrint('HealthService: Not initialized, cannot write sleep stages data');
      return false;
    }

    try {
      debugPrint('HealthService: Writing sleep stages data');
      int successCount = 0;
      int totalWrites = 0;

      // メインの睡眠時間（最も重要）
      try {
        totalWrites++;
        bool mainSleepSuccess = await writeSleepData(
          bedTime: bedTime,
          wakeTime: wakeTime,
          type: HealthDataType.SLEEP_ASLEEP,
        );
        if (mainSleepSuccess) successCount++;
        debugPrint('HealthService: Main sleep write: $mainSleepSuccess');
      } catch (e) {
        debugPrint('HealthService: Main sleep write failed: $e');
      }

      // ベッドタイム
      try {
        totalWrites++;
        bool bedTimeSuccess = await writeSleepData(
          bedTime: bedTime,
          wakeTime: wakeTime,
          type: HealthDataType.SLEEP_IN_BED,
        );
        if (bedTimeSuccess) successCount++;
        debugPrint('HealthService: Bed time write: $bedTimeSuccess');
      } catch (e) {
        debugPrint('HealthService: Bed time write failed: $e');
      }

      // 深い睡眠（オプション）
      if (deepSleepDuration != null && deepSleepDuration.inMinutes > 0) {
        try {
          totalWrites++;
          DateTime deepStart = bedTime;
          DateTime deepEnd = deepStart.add(deepSleepDuration);
          bool deepSleepSuccess = await writeSleepData(
            bedTime: deepStart,
            wakeTime: deepEnd,
            type: HealthDataType.SLEEP_DEEP,
          );
          if (deepSleepSuccess) successCount++;
          debugPrint('HealthService: Deep sleep write: $deepSleepSuccess');
        } catch (e) {
          debugPrint('HealthService: Deep sleep write failed: $e');
        }
      }

      // 浅い睡眠（オプション）
      if (lightSleepDuration != null && lightSleepDuration.inMinutes > 0) {
        try {
          totalWrites++;
          DateTime lightStart = bedTime.add(deepSleepDuration ?? Duration.zero);
          DateTime lightEnd = lightStart.add(lightSleepDuration);
          bool lightSleepSuccess = await writeSleepData(
            bedTime: lightStart,
            wakeTime: lightEnd,
            type: HealthDataType.SLEEP_LIGHT,
          );
          if (lightSleepSuccess) successCount++;
          debugPrint('HealthService: Light sleep write: $lightSleepSuccess');
        } catch (e) {
          debugPrint('HealthService: Light sleep write failed: $e');
        }
      }

      // REM睡眠（オプション）
      if (remSleepDuration != null && remSleepDuration.inMinutes > 0) {
        try {
          totalWrites++;
          Duration previousDuration = (deepSleepDuration ?? Duration.zero) + 
                                    (lightSleepDuration ?? Duration.zero);
          DateTime remStart = bedTime.add(previousDuration);
          DateTime remEnd = remStart.add(remSleepDuration);
          bool remSleepSuccess = await writeSleepData(
            bedTime: remStart,
            wakeTime: remEnd,
            type: HealthDataType.SLEEP_REM,
          );
          if (remSleepSuccess) successCount++;
          debugPrint('HealthService: REM sleep write: $remSleepSuccess');
        } catch (e) {
          debugPrint('HealthService: REM sleep write failed: $e');
        }
      }

      bool overallSuccess = successCount > 0; // 少なくとも1つ成功していればOK
      debugPrint('HealthService: Sleep stages write completed: $successCount/$totalWrites successful, overall: $overallSuccess');
      return overallSuccess;
    } catch (e, stackTrace) {
      debugPrint('HealthService: Failed to write sleep stages data: $e');
      debugPrint('HealthService: Stack trace: $stackTrace');
      return false;
    }
  }

  /// 今日のヘルスサマリーを取得
  Future<Map<String, dynamic>> getTodayHealthSummary() async {
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
      bool sleepSupported = Health().isDataTypeAvailable(HealthDataType.SLEEP_ASLEEP);
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