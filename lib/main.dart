import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 日本語ロケール初期化
  await initializeDateFormatting('ja_JP', null);
  
  // Firebase初期化
  try {
    await FirebaseService.initialize();
    print('Firebase初期化完了');
  } catch (e) {
    print('Firebase初期化エラー（オフラインモードで継続）: $e');
  }
  
  runApp(const SleepApp());
}
