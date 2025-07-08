import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../domain/entities/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../main_screen.dart';

class OnboardingCompletionScreen extends StatefulWidget {
  final String? nickname;
  final String ageGroup;
  final String gender;
  final String? occupation;
  final TimeOfDay weekdayBedtime;
  final TimeOfDay weekdayWakeTime;
  final TimeOfDay weekendBedtime;
  final TimeOfDay weekendWakeTime;
  final List<String> sleepConcerns;
  final String? caffeineHabit;
  final String? alcoholHabit;
  final String? exerciseHabit;
  final String phoneUsageTime;
  final List<String> phoneUsageContent;

  const OnboardingCompletionScreen({
    Key? key,
    this.nickname,
    required this.ageGroup,
    required this.gender,
    this.occupation,
    required this.weekdayBedtime,
    required this.weekdayWakeTime,
    required this.weekendBedtime,
    required this.weekendWakeTime,
    required this.sleepConcerns,
    this.caffeineHabit,
    this.alcoholHabit,
    this.exerciseHabit,
    required this.phoneUsageTime,
    required this.phoneUsageContent,
  }) : super(key: key);

  @override
  State<OnboardingCompletionScreen> createState() => _OnboardingCompletionScreenState();
}

class _OnboardingCompletionScreenState extends State<OnboardingCompletionScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // プログレスバー
          const SafeArea(
            child: OnboardingProgressBar(currentStep: 4, totalSteps: 4),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // 完了アイコン
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.successColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // 完了メッセージ
                  Text(
                    '設定完了！',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    widget.nickname != null 
                        ? '${widget.nickname}さん、ありがとうございました！'
                        : 'ありがとうございました！',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'あなたの情報を元に、より良い睡眠をサポートします。\n素晴らしい睡眠の旅を始めましょう！',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // サマリー表示
                  _buildSummaryCard(),
                  
                  const SizedBox(height: 40),
                  
                  // アプリを始めるボタン
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'アプリを始める',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '設定内容',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem('年齢', widget.ageGroup),
          _buildSummaryItem('性別', widget.gender),
          if (widget.occupation != null)
            _buildSummaryItem('職業', widget.occupation!),
          _buildSummaryItem(
            '平日就寝時刻',
            widget.weekdayBedtime.format(context),
          ),
          _buildSummaryItem(
            '平日起床時刻',
            widget.weekdayWakeTime.format(context),
          ),
          _buildSummaryItem(
            '就寝前スマホ利用',
            widget.phoneUsageTime,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      
      // UserProfileを作成
      final userProfile = UserProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        nickname: widget.nickname,
        ageGroup: widget.ageGroup,
        gender: widget.gender,
        occupation: widget.occupation,
        weekdayBedtime: widget.weekdayBedtime,
        weekdayWakeTime: widget.weekdayWakeTime,
        weekendBedtime: widget.weekendBedtime,
        weekendWakeTime: widget.weekendWakeTime,
        targetBedtime: widget.weekdayBedtime, // デフォルトとして平日の就寝時刻を使用
        targetWakeTime: widget.weekdayWakeTime, // デフォルトとして平日の起床時刻を使用
        sleepConcerns: widget.sleepConcerns,
        caffeineHabit: widget.caffeineHabit,
        alcoholHabit: widget.alcoholHabit,
        exerciseHabit: widget.exerciseHabit,
        phoneUsageTime: widget.phoneUsageTime,
        phoneUsageContent: widget.phoneUsageContent,
        isOnboardingCompleted: true,
      );

      // ユーザープロファイルを保存
      await userProvider.updateProfile(userProfile);
      
      // メイン画面に遷移（全ての画面をクリア）
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('設定の保存に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}