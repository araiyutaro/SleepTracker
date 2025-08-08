import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../firebase_options.dart';
import 'analytics_service.dart';

/// Firebase サービスクラス
/// Google Cloud Platform との通信を担当
class FirebaseService {
  static FirebaseAuth? _auth;
  
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first');
    }
    return _auth!;
  }
  // Cloud Functions HTTPエンドポイント（iOS対応）
  static const String _functionsBaseUrl = 'https://us-central1-sleep-tracker-app-1751975391.cloudfunctions.net';

  static bool _initialized = false;
  
  /// Firebaseが初期化されているかどうか
  static bool get isInitialized => _initialized;

  /// Firebase初期化
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('Checking for Firebase config files...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      print('Firebase初期化完了');
      
      // Firebase Authの初期化
      _auth = FirebaseAuth.instance;
      print('✅ Firebase Auth initialized');
      
      _initialized = true;
      print('✅ Firebase initialization successful');
    } catch (e) {
      print('Firebase初期化エラー: $e');
      print('❌ Firebase initialization failed');
      print('Common causes:');
      print('  1. Missing config files:');
      print('     - android/app/google-services.json');
      print('     - ios/Runner/GoogleService-Info.plist');
      print('  2. Incorrect package name/bundle ID');
      print('  3. firebase_options.dart not generated');
      print('Run: flutterfire configure');
      rethrow;
    }
  }

  /// 匿名認証
  static Future<UserCredential?> signInAnonymously() async {
    try {
      if (!_initialized) {
        throw Exception('Firebase not initialized');
      }
      
      final userCredential = await auth.signInAnonymously();
      print('✅ 匿名認証成功: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('❌ 匿名認証エラー: $e');
      return null;
    }
  }

  /// 現在のユーザーを取得
  static User? getCurrentUser() {
    if (!_initialized) {
      return null;
    }
    return auth.currentUser;
  }

  /// 認証状態を監視
  static Stream<User?> authStateChanges() {
    if (!_initialized) {
      return Stream.value(null);
    }
    return auth.authStateChanges();
  }

  /// サインアウト
  static Future<void> signOut() async {
    try {
      if (!_initialized) {
        return;
      }
      
      await auth.signOut();
      print('✅ サインアウト完了');
    } catch (e) {
      print('❌ サインアウトエラー: $e');
    }
  }

  /// 睡眠データをCloud Functionsにアップロード（HTTP API経由）
  static Future<bool> uploadSleepData({
    required Map<String, dynamic> sleepSession,
    required Map<String, dynamic> userProfile,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return false;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/uploadSleepData'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'sleepSession': sleepSession,
            'userProfile': userProfile,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final success = result['result']['success'] == true;
        if (success) {
          print('睡眠データアップロード成功');
        } else {
          print('睡眠データアップロード失敗: ${result['result']['message']}');
        }
        return success;
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('睡眠データアップロードエラー: $e');
      return false;
    }
  }

  /// グループ分析データを取得（HTTP API経由）
  static Future<Map<String, dynamic>?> getGroupAnalytics({
    required String ageGroup,
    required String occupation,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return null;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/getGroupAnalytics'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'ageGroup': ageGroup,
            'occupation': occupation,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('グループ分析データ取得成功');
        return Map<String, dynamic>.from(result['result']);
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('グループ分析取得エラー: $e');
      return null;
    }
  }

  /// トレンド分析データを取得（HTTP API経由）
  static Future<Map<String, dynamic>?> getTrendAnalytics({
    String period = '30',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/getTrendAnalytics'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': {
            'period': period,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('トレンド分析データ取得成功');
        return Map<String, dynamic>.from(result['result']);
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('トレンド分析取得エラー: $e');
      return null;
    }
  }

  /// ユーザーデータをHTTP API経由で保存
  static Future<bool> saveUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return false;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/saveUserProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'userId': userId,
            'profileData': profileData,
          }
        }),
      );

      if (response.statusCode == 200) {
        print('ユーザープロファイル保存成功');
        return true;
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('ユーザープロファイル保存エラー: $e');
      return false;
    }
  }

  /// ユーザーデータをHTTP API経由で取得
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return null;
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/getUserProfile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'userId': userId,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return Map<String, dynamic>.from(result['result']);
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('ユーザープロファイル取得エラー: $e');
      return null;
    }
  }

  /// 個人の睡眠履歴をHTTP API経由で取得
  static Future<List<Map<String, dynamic>>> getUserSleepHistory({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return [];
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/getUserSleepHistory'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'userId': userId,
            'limit': limit,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return List<Map<String, dynamic>>.from(result['result']);
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('睡眠履歴取得エラー: $e');
      return [];
    }
  }

  /// 日次集計データをHTTP API経由で取得
  static Future<List<Map<String, dynamic>>> getDailyAggregates({
    required String userId,
    int days = 30,
  }) async {
    try {
      final user = getCurrentUser();
      if (user == null) {
        print('ユーザーが認証されていません');
        return [];
      }

      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_functionsBaseUrl/getDailyAggregates'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'data': {
            'userId': userId,
            'days': days,
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        return List<Map<String, dynamic>>.from(result['result']);
      } else {
        print('HTTP エラー: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('日次集計データ取得エラー: $e');
      return [];
    }
  }
}