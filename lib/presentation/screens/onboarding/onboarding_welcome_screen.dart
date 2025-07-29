import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../services/analytics_service.dart';
import '../main_screen.dart';
import '../../providers/user_provider.dart';
import '../../../domain/entities/user_profile.dart';
import 'onboarding_basic_info_screen.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingWelcomeScreen> createState() => _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // オンボーディング開始イベント
    AnalyticsService().logOnboardingStarted();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // キーボード対応を明示
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // デバッグ用ダミーユーザー作成ボタン
          IconButton(
            onPressed: _createDummyUserAndSkip,
            icon: Icon(
              Icons.bug_report,
              color: Colors.grey[400],
            ),
            tooltip: 'デバッグ: ダミーユーザー作成',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // アプリアイコンと名前
                    Icon(
                      Icons.nights_stay,
                      size: 80,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sleep Tracker',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // アプリの説明
                    Text(
                      'より良い睡眠習慣を身につけて、\n健康的な生活を送りましょう',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'あなたの睡眠パターンを記録・分析し、\n質の高い睡眠をサポートします',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // ニックネーム入力
                    Text(
                      'ニックネーム（任意）',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nicknameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        hintText: 'アプリ内で呼ばれる名前を入力してください',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    
                    // キーボード表示時のための余白
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 80),
                  ],
                ),
              ),
            ),
            
            // 始めるボタン（固定位置）
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // オンボーディングステップ完了イベント
                    AnalyticsService().logOnboardingStepCompleted('welcome');
                    
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OnboardingBasicInfoScreen(
                          nickname: _nicknameController.text.trim().isEmpty 
                              ? null 
                              : _nicknameController.text.trim(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '始める',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createDummyUserAndSkip() async {
    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('デバッグ: ダミーユーザー作成中...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('ダミーユーザーデータを作成しています'),
            ],
          ),
        ),
      );

      final userProvider = context.read<UserProvider>();
      
      // ダミーユーザープロファイルを作成
      final dummyProfile = UserProfile(
        id: 'default_user',
        nickname: 'テストユーザー',
        ageGroup: '30代',
        gender: '男性',
        occupation: 'エンジニア',
        targetSleepHours: 7.5,
        targetBedtime: const TimeOfDay(hour: 23, minute: 0),
        targetWakeTime: const TimeOfDay(hour: 6, minute: 30),
        weekdayBedtime: const TimeOfDay(hour: 23, minute: 0),
        weekdayWakeTime: const TimeOfDay(hour: 6, minute: 30),
        weekendBedtime: const TimeOfDay(hour: 23, minute: 30),
        weekendWakeTime: const TimeOfDay(hour: 7, minute: 30),
        sleepConcerns: ['寝つきが悪い', '夜中に目が覚める'],
        caffeineHabit: '1日2-3杯',
        alcoholHabit: '週1-2回',
        exerciseHabit: '週3-4回',
        phoneUsageTime: '1-2時間',
        phoneUsageContent: ['SNS', '動画視聴'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notificationSettings: NotificationSettings(
          bedtimeReminderEnabled: true,
          wakeUpAlarmEnabled: true,
          sleepQualityNotificationEnabled: true,
          weeklyReportEnabled: true,
        ),
        isOnboardingCompleted: true,
      );

      // ユーザープロファイルを保存
      await userProvider.updateProfile(dummyProfile);
      
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog を閉じる
        
        // メイン画面へ直接移動
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
          (route) => false,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('デバッグ: ダミーユーザーを作成してオンボーディングをスキップしました'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog を閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ダミーユーザー作成に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}