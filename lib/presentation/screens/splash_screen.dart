import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/themes/app_theme.dart';
import '../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../services/firebase_service.dart';
import 'main_screen.dart';
import 'research_consent_screen.dart';
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
      debugPrint('🔄 SplashScreen: Starting app initialization...');
      
      // UserProviderの初期化を待つ
      debugPrint('🔄 SplashScreen: Initializing UserProvider...');
      final userProvider = context.read<UserProvider>();
      await userProvider.initialize();
      debugPrint('✅ SplashScreen: UserProvider initialized');
      
      // プッシュ通知サービスを初期化（Firebaseが初期化済みの場合のみ）
      if (FirebaseService.isInitialized) {
        try {
          debugPrint('🔄 SplashScreen: Initializing NotificationService...');
          await NotificationService().initialize();
          debugPrint('✅ NotificationService初期化完了');
        } catch (e) {
          debugPrint('⚠️ NotificationService初期化エラー: $e');
        }
      } else {
        debugPrint('⚠️ SplashScreen: Firebase not initialized, skipping NotificationService');
      }
      
      // 少し待機してスプラッシュ画面を表示
      debugPrint('🔄 SplashScreen: Waiting for splash display...');
      await Future.delayed(const Duration(seconds: 2));
      debugPrint('✅ SplashScreen: Splash delay completed');
      
      if (mounted) {
        debugPrint('🔄 SplashScreen: Checking navigation state...');
        
        // 研究同意状態をチェック
        final prefs = await SharedPreferences.getInstance();
        final hasSeenConsentScreen = prefs.containsKey('research_consent_given');
        debugPrint('🔍 SplashScreen: hasSeenConsentScreen = $hasSeenConsentScreen');
        
        if (!hasSeenConsentScreen) {
          // 初回起動 -> 研究同意画面へ
          debugPrint('🔄 SplashScreen: Navigating to ResearchConsentScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ResearchConsentScreen()),
          );
          return;
        }
        
        // オンボーディング完了状態をチェック
        final profile = userProvider.profile;
        debugPrint('🔍 SplashScreen: Profile exists: ${profile != null}');
        if (profile != null) {
          debugPrint('🔍 SplashScreen: isOnboardingCompleted: ${profile.isOnboardingCompleted}');
        }
        final isOnboardingCompleted = profile?.isOnboardingCompleted ?? false;
        
        if (isOnboardingCompleted) {
          // オンボーディング完了済み -> メイン画面へ
          debugPrint('🔄 SplashScreen: Navigating to MainScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // オンボーディング未完了 -> オンボーディング画面へ
          debugPrint('🔄 SplashScreen: Navigating to OnboardingWelcomeScreen');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OnboardingWelcomeScreen()),
          );
        }
      } else {
        debugPrint('⚠️ SplashScreen: Widget not mounted, skipping navigation');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ SplashScreen: アプリ初期化エラー: $e');
      debugPrint('❌ SplashScreen: Stack trace: $stackTrace');
      if (mounted) {
        // エラーが発生した場合は研究同意画面から開始
        debugPrint('🔄 SplashScreen: Error recovery - navigating to ResearchConsentScreen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ResearchConsentScreen()),
        );
      } else {
        debugPrint('⚠️ SplashScreen: Widget not mounted during error recovery');
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