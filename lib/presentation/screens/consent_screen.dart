import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'legal_screen.dart';
import 'onboarding_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute(builder: (_) => const ConsentScreen());
  }

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyPolicyAccepted = false;
  bool _termsOfServiceAccepted = false;
  bool _isLoading = false;

  bool get _canProceed => _privacyPolicyAccepted && _termsOfServiceAccepted;

  Future<void> _saveConsentAndProceed() async {
    if (!_canProceed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_policy_accepted', true);
      await prefs.setBool('terms_of_service_accepted', true);
      await prefs.setString('consent_date', DateTime.now().toIso8601String());

      if (mounted) {
        Navigator.of(context).pushReplacement(OnboardingScreen.route());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('利用開始前の確認'),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // アプリロゴ・アイコンエリア
            const SizedBox(height: 32),
            const Icon(
              Icons.bedtime,
              size: 80,
              color: Color(0xFF4A90E2),
            ),
            const SizedBox(height: 24),
            
            // アプリ名
            Text(
              'Sleep Tracker',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A90E2),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // サブタイトル
            Text(
              'より良い睡眠習慣を築くお手伝いをします',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 48),
            
            // 説明文
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ご利用開始前に',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sleep Trackerは、あなたの睡眠データを分析し、より良い睡眠習慣をサポートします。'
                      'アプリをご利用いただく前に、以下の利用規約とプライバシーポリシーをご確認いただき、'
                      '同意いただく必要があります。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 利用規約同意チェックボックス
            Card(
              child: CheckboxListTile(
                value: _termsOfServiceAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsOfServiceAccepted = value ?? false;
                  });
                },
                title: const Text('利用規約に同意します'),
                subtitle: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(TermsOfServiceScreen.route());
                  },
                  child: const Text(
                    '利用規約を確認する',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // プライバシーポリシー同意チェックボックス
            Card(
              child: CheckboxListTile(
                value: _privacyPolicyAccepted,
                onChanged: (value) {
                  setState(() {
                    _privacyPolicyAccepted = value ?? false;
                  });
                },
                title: const Text('プライバシーポリシーに同意します'),
                subtitle: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(PrivacyPolicyScreen.route());
                  },
                  child: const Text(
                    'プライバシーポリシーを確認する',
                    style: TextStyle(
                      color: Color(0xFF4A90E2),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            
            const Spacer(),
            
            // 開始ボタン
            ElevatedButton(
              onPressed: _canProceed && !_isLoading ? _saveConsentAndProceed : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Sleep Trackerを開始する',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            
            const SizedBox(height: 16),
            
            // 注意事項
            Text(
              '※ 本アプリは医療機器ではありません。医学的な診断や治療には使用できません。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}