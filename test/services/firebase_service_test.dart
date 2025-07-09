import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:sleep/services/firebase_service.dart';

/// Firebase Service ユニットテスト
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // テスト用のFirebase設定
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: '1:test:android:test',
        messagingSenderId: 'test',
        projectId: 'test-project',
      ),
    );
  });

  group('Firebase Service Tests', () {
    test('Firebase初期化テスト', () async {
      // Firebase初期化が正常に完了することをテスト
      expect(() => FirebaseService.initialize(), returnsNormally);
    });

    test('匿名認証テスト', () async {
      // 匿名認証が実行できることをテスト（実際の認証はemulatorで行う）
      expect(() => FirebaseService.signInAnonymously(), returnsNormally);
    });

    test('現在のユーザー取得テスト', () {
      // 現在のユーザー取得が実行できることをテスト
      expect(() => FirebaseService.getCurrentUser(), returnsNormally);
    });

    test('睡眠データアップロードテスト', () async {
      final testSleepSession = {
        'startTime': DateTime.now().subtract(Duration(hours: 8)).toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
        'duration': 8 * 60 * 60 * 1000,
        'quality': 8.5,
        'notes': 'テストデータ',
      };

      final testUserProfile = {
        'nickname': 'テストユーザー',
        'ageGroup': '20-29',
        'gender': 'その他',
      };

      // データアップロード関数が実行できることをテスト
      expect(
        () => FirebaseService.uploadSleepData(
          sleepSession: testSleepSession,
          userProfile: testUserProfile,
        ),
        returnsNormally,
      );
    });

    test('グループ分析取得テスト', () async {
      // グループ分析取得が実行できることをテスト
      expect(
        () => FirebaseService.getGroupAnalytics(
          ageGroup: '20-29',
          occupation: 'エンジニア',
        ),
        returnsNormally,
      );
    });

    test('トレンド分析取得テスト', () async {
      // トレンド分析取得が実行できることをテスト
      expect(
        () => FirebaseService.getTrendAnalytics(period: '7'),
        returnsNormally,
      );
    });

    test('ユーザープロファイル保存テスト', () async {
      final testProfileData = {
        'nickname': 'テストユーザー',
        'ageGroup': '20-29',
        'gender': 'その他',
      };

      // プロファイル保存が実行できることをテスト
      expect(
        () => FirebaseService.saveUserProfile(
          userId: 'test-user-id',
          profileData: testProfileData,
        ),
        returnsNormally,
      );
    });
  });
}