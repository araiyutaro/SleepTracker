import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/firebase_service.dart';
import 'services/analytics_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日本語ロケール初期化
  await initializeDateFormatting('ja_JP', null);
  
  // Firebase初期化（安全な方法で）
  print('Firebase初期化を開始...');
  
  try {
    // AnalyticsServiceを先に初期化（スタブモードで）
    AnalyticsService().initializeStub();
    print('AnalyticsService: スタブモードで初期化完了');
    
    // Firebase初期化を試行
    await FirebaseService.initialize();
    print('Firebase初期化完了');
    
    // Firebase初期化に成功した場合、AnalyticsServiceを再初期化
    AnalyticsService().initialize();
    print('AnalyticsService: Firebase連携モードで再初期化完了');
  } catch (e) {
    print('Firebase初期化エラー（オフラインモードで継続）: $e');
    // Firebase初期化に失敗した場合はスタブモードを維持
    print('AnalyticsService: スタブモードを維持');
  }
  
  runApp(const SleepApp());
}
