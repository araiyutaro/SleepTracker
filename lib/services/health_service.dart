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
    } catch (e) {
      // Initialization failed - continue without health integration
    }
  }

  /// 権限要求（オプション機能）
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final permissions = [
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
      ];
      
      // プラットフォームサポート確認
      bool isSupported = Health().isDataTypeAvailable(HealthDataType.SLEEP_ASLEEP);
      
      if (!isSupported) {
        return false;
      }
      
      bool requested = await _health.requestAuthorization(types, permissions: permissions);
      
      return requested;
    } catch (e, stackTrace) {
      return false;
    }
  }

  /// 権限確認
  Future<bool> hasPermissions() async {
    if (!_isInitialized) {
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
      ];

      final types = [
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
      ];
      
      bool? hasPermissions = await _health.hasPermissions(types, permissions: permissions);
      
      return hasPermissions ?? false;
    } catch (e, stackTrace) {
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
      return false;
    }

    try {
      bool success = await _health.writeHealthData(
        value: 0, // 睡眠の場合、値は使用されない
        type: type,
        startTime: bedTime,
        endTime: wakeTime,
      );
      return success;
    } catch (e, stackTrace) {
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
      return false;
    }

    try {
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
      } catch (e) {
        // Main sleep write failed
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
      } catch (e) {
        // Bed time write failed
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
        } catch (e) {
          // Deep sleep write failed
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
        } catch (e) {
          // Light sleep write failed
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
        } catch (e) {
          // REM sleep write failed
        }
      }

      bool overallSuccess = successCount > 0; // 少なくとも1つ成功していればOK
      return overallSuccess;
    } catch (e, stackTrace) {
      return false;
    }
  }

  /// 今日のヘルスサマリーを取得
  Future<Map<String, dynamic>> getTodayHealthSummary() async {
    try {
      // 基本的な空のデータを返す（睡眠データのみ）
      return {
        'sleepData': <HealthDataPoint>[],
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      return {
        'sleepData': <HealthDataPoint>[],
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
      
      return sleepSupported;
    } catch (e, stackTrace) {
      return false;
    }
  }

  /// 初期化状態確認
  bool get isInitialized => _isInitialized;
}