import 'package:flutter/foundation.dart';
import '../../services/firebase_service.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/sleep_session.dart';

/// サーバーレス分析プロバイダー
/// Google Cloud Functions を通じてサーバーサイド分析機能を提供
class ServerlessAnalyticsProvider with ChangeNotifier {
  Map<String, dynamic>? _groupAnalytics;
  Map<String, dynamic>? _trendAnalytics;
  List<Map<String, dynamic>> _cloudSleepHistory = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isConnected = false;

  // Getters
  Map<String, dynamic>? get groupAnalytics => _groupAnalytics;
  Map<String, dynamic>? get trendAnalytics => _trendAnalytics;
  List<Map<String, dynamic>> get cloudSleepHistory => _cloudSleepHistory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;

  /// Firebase接続状態を確認
  Future<void> checkConnection() async {
    try {
      await FirebaseService.initialize();
      final user = await FirebaseService.signInAnonymously();
      _isConnected = user != null;
      
      if (_isConnected) {
        print('Firebase接続成功: ${user!.uid}');
      } else {
        _errorMessage = 'Firebase接続に失敗しました';
      }
    } catch (e) {
      _isConnected = false;
      _errorMessage = 'Firebase初期化エラー: $e';
    }
    
    notifyListeners();
  }

  /// グループ比較データを取得
  Future<void> loadGroupAnalytics(UserProfile userProfile) async {
    if (!_isConnected) {
      _errorMessage = 'Firebaseに接続されていません';
      notifyListeners();
      return;
    }

    if (userProfile.ageGroup == null || userProfile.occupation == null) {
      _errorMessage = '年齢グループまたは職業が設定されていません';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final result = await FirebaseService.getGroupAnalytics(
        ageGroup: userProfile.ageGroup!,
        occupation: userProfile.occupation!,
      );

      _groupAnalytics = result;
      _errorMessage = null;
      
      if (result != null) {
        print('グループ分析データ取得完了: ${result['sampleSize']}件のサンプル');
      }
    } catch (e) {
      _errorMessage = 'グループ分析の取得に失敗しました: $e';
      print('グループ分析エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// トレンド分析データを取得
  Future<void> loadTrendAnalytics({String period = '30'}) async {
    if (!_isConnected) {
      _errorMessage = 'Firebaseに接続されていません';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final result = await FirebaseService.getTrendAnalytics(period: period);
      
      _trendAnalytics = result;
      _errorMessage = null;
      
      if (result != null) {
        print('トレンド分析データ取得完了: ${result['summary']['dataPoints']}データポイント');
      }
    } catch (e) {
      _errorMessage = 'トレンド分析の取得に失敗しました: $e';
      print('トレンド分析エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 睡眠セッションをクラウドにアップロード
  Future<bool> uploadSleepSession({
    required SleepSession sleepSession,
    required UserProfile userProfile,
  }) async {
    if (!_isConnected) {
      _errorMessage = 'Firebaseに接続されていません';
      notifyListeners();
      return false;
    }

    try {
      final sleepSessionData = {
        'id': sleepSession.id,
        'startTime': sleepSession.startTime.millisecondsSinceEpoch,
        'endTime': sleepSession.endTime?.millisecondsSinceEpoch,
        'duration': sleepSession.calculatedDuration.inMinutes,
        'qualityScore': sleepSession.qualityScore ?? 0.0,
        'movements': sleepSession.movements.map((m) => {
          'timestamp': m.timestamp.millisecondsSinceEpoch,
          'intensity': m.intensity,
        }).toList(),
        'sleepStages': sleepSession.sleepStages != null ? {
          'deepSleepPercentage': sleepSession.sleepStages!.deepSleepPercentage,
          'lightSleepPercentage': sleepSession.sleepStages!.lightSleepPercentage,
          'remSleepPercentage': sleepSession.sleepStages!.remSleepPercentage,
          'awakePercentage': sleepSession.sleepStages!.awakePercentage,
          'movementCount': sleepSession.sleepStages!.movementCount,
        } : null,
      };

      final userProfileData = {
        'ageGroup': userProfile.ageGroup,
        'occupation': userProfile.occupation,
        'phoneUsageTime': userProfile.phoneUsageTime,
        'sleepConcerns': userProfile.sleepConcerns,
      };

      final success = await FirebaseService.uploadSleepData(
        sleepSession: sleepSessionData,
        userProfile: userProfileData,
      );

      if (success) {
        print('睡眠データアップロード成功');
        // ローカルキャッシュも更新
        await _refreshCloudData();
      } else {
        _errorMessage = '睡眠データのアップロードに失敗しました';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'アップロードエラー: $e';
      print('睡眠データアップロードエラー: $e');
      notifyListeners();
      return false;
    }
  }

  /// クラウドから睡眠履歴を取得
  Future<void> loadCloudSleepHistory() async {
    if (!_isConnected) {
      _errorMessage = 'Firebaseに接続されていません';
      notifyListeners();
      return;
    }

    final user = FirebaseService.getCurrentUser();
    if (user == null) {
      _errorMessage = 'ユーザーが認証されていません';
      notifyListeners();
      return;
    }

    _setLoading(true);

    try {
      final history = await FirebaseService.getUserSleepHistory(
        userId: user.uid,
        limit: 50,
      );

      _cloudSleepHistory = history;
      _errorMessage = null;
      
      print('クラウド睡眠履歴取得完了: ${history.length}件');
    } catch (e) {
      _errorMessage = 'クラウド履歴の取得に失敗しました: $e';
      print('クラウド履歴取得エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// クラウドデータを同期
  Future<void> syncWithCloud() async {
    if (!_isConnected) {
      await checkConnection();
      if (!_isConnected) return;
    }

    _setLoading(true);

    try {
      // 複数のデータを並行して取得
      await Future.wait([
        loadCloudSleepHistory(),
        // 必要に応じて他のデータも同期
      ]);

      print('クラウド同期完了');
    } catch (e) {
      _errorMessage = 'クラウド同期に失敗しました: $e';
      print('クラウド同期エラー: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// エラーメッセージをクリア
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 接続状態をリセット
  void resetConnection() {
    _isConnected = false;
    _groupAnalytics = null;
    _trendAnalytics = null;
    _cloudSleepHistory.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// プライベートメソッド

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _refreshCloudData() async {
    // バックグラウンドでデータを更新（UIブロックしない）
    loadCloudSleepHistory();
  }

  /// 統計情報の取得
  Map<String, dynamic> getConnectionStats() {
    return {
      'isConnected': _isConnected,
      'cloudHistoryCount': _cloudSleepHistory.length,
      'hasGroupAnalytics': _groupAnalytics != null,
      'hasTrendAnalytics': _trendAnalytics != null,
      'lastError': _errorMessage,
    };
  }

  /// グループ分析の比較データを取得
  Map<String, dynamic>? getComparisonData() {
    if (_groupAnalytics == null) return null;
    
    return {
      'avgSleepDuration': _groupAnalytics!['avgSleepDuration'] ?? 0,
      'avgSleepQuality': _groupAnalytics!['avgSleepQuality'] ?? 0,
      'sampleSize': _groupAnalytics!['sampleSize'] ?? 0,
      'ageGroup': _groupAnalytics!['ageGroup'] ?? '',
      'occupation': _groupAnalytics!['occupation'] ?? '',
    };
  }

  /// トレンドサマリーを取得
  Map<String, dynamic>? getTrendSummary() {
    if (_trendAnalytics == null) return null;
    
    final summary = _trendAnalytics!['summary'];
    return {
      'avgDuration': summary['avgDuration'] ?? 0,
      'avgQuality': summary['avgQuality'] ?? 0,
      'trend': summary['trend'] ?? 'unknown',
      'dataPoints': summary['dataPoints'] ?? 0,
    };
  }
}