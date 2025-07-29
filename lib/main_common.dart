import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/firebase_service.dart';
import 'services/analytics_service.dart';
import 'services/notification_service.dart';
import 'app.dart';
import 'config/flavor_config.dart';

Future<void> mainCommon() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter binding initialized');
    
    // 日本語ロケール初期化
    await initializeDateFormatting('ja_JP', null);
    print('✅ Japanese locale initialized');
    
    // Firebase初期化（安全な方法で）
    print('🔄 Starting Firebase initialization for ${FlavorConfig.name} environment...');
    
    try {
      // AnalyticsServiceを先に初期化（スタブモードで）
      AnalyticsService().initializeStub();
      print('✅ AnalyticsService: スタブモードで初期化完了');
      
      // Firebase初期化を試行
      await FirebaseService.initialize();
      print('✅ Firebase初期化完了');
      
      // Firebase初期化に成功した場合、AnalyticsServiceを再初期化
      AnalyticsService().initialize();
      print('✅ AnalyticsService: Firebase連携モードで再初期化完了');
      print('🚀 Firebase services are ready - Push notifications will be available');
    } catch (e) {
      print('⚠️ Firebase初期化エラー（オフラインモードで継続）: $e');
      // Firebase初期化に失敗した場合はスタブモードを維持
      print('✅ AnalyticsService: スタブモードを維持');
    }
    
    print('🚀 Starting SleepApp in ${FlavorConfig.name} mode...');
    runApp(const SleepApp());
  } catch (e, stackTrace) {
    print('❌ FATAL ERROR in main(): $e');
    print('Stack trace: $stackTrace');
    // 最小限のエラー表示アプリを起動
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text(
                'アプリの初期化に失敗しました (${FlavorConfig.name})',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'エラー: $e',
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ));
  }
}