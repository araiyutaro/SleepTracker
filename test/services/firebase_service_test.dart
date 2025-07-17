import 'package:flutter_test/flutter_test.dart';
import 'package:sleep/services/firebase_service.dart';

/// Firebase Service ユニットテスト
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Firebase Service Tests', () {
    // Firebaseテストはテスト環境での実行が困難なため、現在はスキップ
    test('Firebase Service is available', () {
      // FirebaseServiceクラスが利用可能であることを確認
      expect(FirebaseService, isNotNull);
    });
  }, skip: 'Firebase tests require emulator setup');
}