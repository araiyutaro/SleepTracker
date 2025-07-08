import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Firebase サービスクラス
/// Google Cloud Platform との通信を担当
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static bool _initialized = false;

  /// Firebase初期化
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      await Firebase.initializeApp();
      
      // 開発環境ではローカルエミュレーターを使用
      // _functions.useFunctionsEmulator('localhost', 5001);
      // _firestore.useFirestoreEmulator('localhost', 8080);
      // _auth.useAuthEmulator('localhost', 9099);
      
      _initialized = true;
      print('Firebase初期化完了');
    } catch (e) {
      print('Firebase初期化エラー: $e');
      rethrow;
    }
  }

  /// 匿名認証
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      print('匿名認証成功: ${userCredential.user?.uid}');
      return userCredential.user;
    } catch (e) {
      print('匿名認証エラー: $e');
      return null;
    }
  }

  /// 現在のユーザーを取得
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// 認証状態を監視
  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  /// サインアウト
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('サインアウト完了');
    } catch (e) {
      print('サインアウトエラー: $e');
    }
  }

  /// 睡眠データをCloud Functionsにアップロード
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

      final callable = _functions.httpsCallable('uploadSleepData');
      final result = await callable.call({
        'sleepSession': sleepSession,
        'userProfile': userProfile,
      });

      final success = result.data['success'] == true;
      if (success) {
        print('睡眠データアップロード成功');
      } else {
        print('睡眠データアップロード失敗: ${result.data['message']}');
      }
      
      return success;
    } on FirebaseFunctionsException catch (e) {
      print('Cloud Function呼び出しエラー: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('睡眠データアップロードエラー: $e');
      return false;
    }
  }

  /// グループ分析データを取得
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

      final callable = _functions.httpsCallable('getGroupAnalytics');
      final result = await callable.call({
        'ageGroup': ageGroup,
        'occupation': occupation,
      });

      print('グループ分析データ取得成功');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('グループ分析取得エラー: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('グループ分析取得エラー: $e');
      return null;
    }
  }

  /// トレンド分析データを取得
  static Future<Map<String, dynamic>?> getTrendAnalytics({
    String period = '30',
  }) async {
    try {
      final callable = _functions.httpsCallable('getTrendAnalytics');
      final result = await callable.call({
        'period': period,
      });

      print('トレンド分析データ取得成功');
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      print('トレンド分析取得エラー: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('トレンド分析取得エラー: $e');
      return null;
    }
  }

  /// ユーザーデータをFirestoreに保存
  static Future<bool> saveUserProfile({
    required String userId,
    required Map<String, dynamic> profileData,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set({'profile': profileData}, SetOptions(merge: true));
      
      print('ユーザープロファイル保存成功');
      return true;
    } catch (e) {
      print('ユーザープロファイル保存エラー: $e');
      return false;
    }
  }

  /// ユーザーデータをFirestoreから取得
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['profile'];
      }
      return null;
    } catch (e) {
      print('ユーザープロファイル取得エラー: $e');
      return null;
    }
  }

  /// 個人の睡眠履歴を取得
  static Future<List<Map<String, dynamic>>> getUserSleepHistory({
    required String userId,
    int limit = 30,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sleepSessions')
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('睡眠履歴取得エラー: $e');
      return [];
    }
  }

  /// 日次集計データを取得
  static Future<List<Map<String, dynamic>>> getDailyAggregates({
    required String userId,
    int days = 30,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dailyAggregates')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String().split('T')[0])
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String().split('T')[0])
          .orderBy('date', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('日次集計データ取得エラー: $e');
      return [];
    }
  }
}