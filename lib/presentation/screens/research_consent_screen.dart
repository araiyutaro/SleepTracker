import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/themes/app_theme.dart';
import '../../services/analytics_service.dart';
import 'onboarding/onboarding_welcome_screen.dart';

class ResearchConsentScreen extends StatefulWidget {
  const ResearchConsentScreen({Key? key}) : super(key: key);

  @override
  State<ResearchConsentScreen> createState() => _ResearchConsentScreenState();
}

class _ResearchConsentScreenState extends State<ResearchConsentScreen> {
  bool _consentGiven = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      
                      // ヘッダー
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.science,
                              size: 64,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '研究協力のお願い',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 研究概要
                      _buildSectionTitle('研究の目的'),
                      _buildSectionContent(
                        'このアプリで収集される睡眠データおよび利用ログは、睡眠の質改善に関する修士論文研究のために利用されます。'
                        'より良い睡眠支援システムの開発を目的としています。'
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 収集データ
                      _buildSectionTitle('収集するデータ'),
                      _buildSectionContent(
                        '• 睡眠計測データ（睡眠時間、起床時間、睡眠品質等）\n'
                        '• アプリ利用ログ（機能の使用状況、操作履歴等）\n'
                        '• ユーザー属性情報（年齢層、性別、職業等）\n'
                        '※個人を特定する情報（氏名、住所等）は一切収集いたしません。'
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // データ利用方法
                      _buildSectionTitle('データの利用方法'),
                      _buildSectionContent(
                        '• 収集したデータは統計的に処理・分析されます\n'
                        '• 個人が特定できる形での公表は一切行いません\n'
                        '• 研究論文での発表や学会での報告に利用される場合があります\n'
                        '• データは厳重に管理され、研究目的以外では使用されません'
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 個人情報保護
                      _buildSectionTitle('個人情報の保護'),
                      _buildSectionContent(
                        '• すべてのデータは匿名化されて処理されます\n'
                        '• データは暗号化して安全に保管されます\n'
                        '• 研究終了後は適切にデータを削除いたします\n'
                        '• 第三者への提供は一切行いません'
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 同意の撤回
                      _buildSectionTitle('同意の撤回について'),
                      _buildSectionContent(
                        '研究への同意はいつでも撤回できます。同意を撤回される場合は、'
                        '下記の問い合わせ先までご連絡ください。撤回された場合、'
                        'それまでに収集したデータは速やかに削除いたします。'
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // 問い合わせ先
                      _buildSectionTitle('問い合わせ先'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '研究責任者：新井雄太郎',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'メールアドレス：bm242001@g.hit-u.ac.jp',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ご質問やご不明な点がございましたら、お気軽にお問い合わせください。',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 同意チェックボックス
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _consentGiven = !_consentGiven;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _consentGiven,
                                onChanged: (value) {
                                  setState(() {
                                    _consentGiven = value ?? false;
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    '上記の内容を理解し、睡眠データおよび利用ログを研究目的で利用することに同意します。',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 注意事項
                      Text(
                        '※ 研究への協力は任意です。同意されない場合でも、アプリのすべての機能をご利用いただけます。',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // ボタン
              const SizedBox(height: 24),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _consentGiven && !_isLoading ? _proceedWithConsent : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              '同意してアプリを始める',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: !_isLoading ? _proceedWithoutConsent : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[400]!),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '同意せずにアプリを始める',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Colors.grey[800],
      ),
    );
  }

  Future<void> _proceedWithConsent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 同意情報を保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('research_consent_given', true);
      await prefs.setString('research_consent_date', DateTime.now().toIso8601String());

      // Analytics: 研究同意イベント
      await AnalyticsService().logCustomEvent('research_consent_given', parameters: {
        'consent': true,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Analyticsを有効化
      await AnalyticsService().setAnalyticsCollectionEnabled(true);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingWelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _proceedWithoutConsent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 非同意情報を保存
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('research_consent_given', false);
      await prefs.setString('research_consent_date', DateTime.now().toIso8601String());

      // Analytics: 研究非同意イベント（最小限のデータのみ）
      await AnalyticsService().logCustomEvent('research_consent_given', parameters: {
        'consent': false,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // Analyticsを無効化
      await AnalyticsService().setAnalyticsCollectionEnabled(false);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const OnboardingWelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving consent: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

}