import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme.dart';
import '../providers/user_provider.dart';
import 'main_screen.dart';
import 'onboarding/onboarding_welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // UserProviderの初期化を待つ
      final userProvider = context.read<UserProvider>();
      await userProvider.initialize();
      
      // 少し待機してスプラッシュ画面を表示
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        // オンボーディング完了状態をチェック
        final isOnboardingCompleted = userProvider.profile?.isOnboardingCompleted ?? false;
        
        if (isOnboardingCompleted) {
          // オンボーディング完了済み -> メイン画面へ
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // オンボーディング未完了 -> オンボーディング画面へ
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingWelcomeScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('アプリ初期化エラー: $e');
      if (mounted) {
        // エラーが発生した場合はオンボーディングから開始
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingWelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アプリアイコン
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(
                Icons.nights_stay,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            
            // アプリ名
            const Text(
              'Sleep Tracker',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'より良い睡眠を、より豊かな毎日を',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 60),
            
            // ローディングインジケーター
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}