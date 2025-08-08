import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_literacy_test_provider.dart';
import '../providers/user_provider.dart';
import '../../services/firestore_service.dart';
import '../../data/datasources/sleep_literacy_questions_data.dart';

// 睡眠リテラシーテスト結果画面
class SleepLiteracyTestResultScreen extends StatefulWidget {
  const SleepLiteracyTestResultScreen({super.key});

  @override
  State<SleepLiteracyTestResultScreen> createState() => _SleepLiteracyTestResultScreenState();
}

class _SleepLiteracyTestResultScreenState extends State<SleepLiteracyTestResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;
  bool _scoresSaved = false;

  @override
  void initState() {
    super.initState();
    
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scoreAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOut,
    ));

    // アニメーション開始とスコア保存
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scoreAnimationController.forward();
      _saveTestResults();
    });
  }

  Future<void> _saveTestResults() async {
    if (_scoresSaved) return;
    
    final testProvider = context.read<SleepLiteracyTestProvider>();
    final userProvider = context.read<UserProvider>();
    final test = testProvider.currentTest;
    
    if (test != null) {
      // ユーザープロファイルにスコアを保存
      await userProvider.updateSleepLiteracyScore(
        test.score,
        test.durationMinutes ?? 0,
        test.categoryScores,
      );
      
      // Firestoreにもテスト結果を保存
      try {
        await FirestoreService().saveTestResult(test);
      } catch (e) {
        debugPrint('Failed to save test result to Firestore: $e');
      }
      
      _scoresSaved = true;
    }
  }

  @override
  void dispose() {
    _scoreAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepLiteracyTestProvider>(
      builder: (context, testProvider, child) {
        final test = testProvider.currentTest;
        
        if (test == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  
                  // 完了アイコン
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF28A745),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // タイトル
                  const Text(
                    'ご協力ありがとうございました',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // スコア表示
                  AnimatedBuilder(
                    animation: _scoreAnimation,
                    builder: (context, child) {
                      return _buildScoreCard(test, _scoreAnimation.value);
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 詳細統計
                  _buildDetailedStats(test),
                  
                  const SizedBox(height: 24),
                  
                  // 回答詳細
                  _buildAnswerDetails(test),
                  
                  const SizedBox(height: 40),
                  
                  // アクションボタン
                  _buildActionButtons(context, test),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreCard(dynamic test, double animationValue) {
    final displayScore = (test.score * animationValue).round();
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A90E2),
            Color(0xFF357ABD),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'あなたのスコア',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$displayScore',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' / 10',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '正答率: ${(test.score / 10 * 100).round()}%',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailedStats(dynamic test) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '詳細統計',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatRow(
            Icons.quiz,
            '回答数',
            '${test.answeredCount} / ${test.questions.length}',
          ),
          
          _buildStatRow(
            Icons.check_circle,
            '正解数',
            '${test.score} / ${test.questions.length}',
          ),
          
          _buildStatRow(
            Icons.help_outline,
            '「分からない」回答',
            '${test.unknownAnswersCount}問',
          ),
          
          if (test.durationMinutes != null)
            _buildStatRow(
              Icons.timer,
              '所要時間',
              '${test.durationMinutes}分',
            ),
        ],
      ),
    );
  }
  
  Widget _buildAnswerDetails(dynamic test) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.list_alt,
                size: 20,
                color: Color(0xFF495057),
              ),
              const SizedBox(width: 8),
              const Text(
                '回答と正解',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF495057),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 各問題の回答と正解を表示
          ...test.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            final userAnswer = test.userAnswers[index];
            final isCorrect = userAnswer >= 0 && userAnswer == question.correctAnswer;
            final isUnknown = userAnswer == 4; // 「分からない」は選択肢4番目（0-indexed）
            final isUnanswered = userAnswer < 0; // 未回答の場合
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect 
                    ? const Color(0xFF28A745).withOpacity(0.05)
                    : isUnknown
                        ? const Color(0xFF6C757D).withOpacity(0.05)
                        : isUnanswered
                            ? const Color(0xFFFFC107).withOpacity(0.05)
                            : const Color(0xFFDC3545).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect
                      ? const Color(0xFF28A745).withOpacity(0.2)
                      : isUnknown
                          ? const Color(0xFF6C757D).withOpacity(0.2)
                          : isUnanswered
                              ? const Color(0xFFFFC107).withOpacity(0.2)
                              : const Color(0xFFDC3545).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect 
                            ? Icons.check_circle 
                            : isUnknown 
                                ? Icons.help 
                                : isUnanswered
                                    ? Icons.warning
                                    : Icons.cancel,
                        size: 18,
                        color: isCorrect 
                            ? const Color(0xFF28A745)
                            : isUnknown
                                ? const Color(0xFF6C757D)
                                : isUnanswered
                                    ? const Color(0xFFFFC107)
                                    : const Color(0xFFDC3545),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '問${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF495057),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        isCorrect 
                            ? '正解' 
                            : isUnknown 
                                ? '分からない' 
                                : isUnanswered
                                    ? '未回答'
                                    : '不正解',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCorrect 
                              ? const Color(0xFF28A745)
                              : isUnknown
                                  ? const Color(0xFF6C757D)
                                  : isUnanswered
                                      ? const Color(0xFFFFC107)
                                      : const Color(0xFFDC3545),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // あなたの回答
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あなたの回答: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6C757D),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          isUnanswered 
                              ? '未回答'
                              : '(${SleepLiteracyQuestionsData.getOptionLabel(userAnswer)}) ${question.options[userAnswer]}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnanswered 
                                ? const Color(0xFFFFC107)
                                : const Color(0xFF495057),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // 正解
                  if (!isCorrect && !isUnanswered) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '正解: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF28A745),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '(${SleepLiteracyQuestionsData.getOptionLabel(question.correctAnswer)}) ${question.options[question.correctAnswer]}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF28A745),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6C757D)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF495057),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic test) {
    return Column(
      children: [
        // メインアクションボタン
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'アプリを始める',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // 詳細表示ボタン
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              _showDetailedResults(context, test);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              '結果の詳細を見る',
              style: TextStyle(
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailedResults(BuildContext context, dynamic test) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ハンドル
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    '詳細結果',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // カテゴリー別スコア
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        const Text(
                          'カテゴリー別結果',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF495057),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        ...test.categoryScores.entries.map((entry) {
                          final category = entry.key;
                          final scores = entry.value;
                          final correct = scores['correct'] ?? 0;
                          final total = scores['total'] ?? 0;
                          final percentage = total > 0 ? (correct / total * 100).round() : 0;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE9ECEF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF495057),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$correct/$total問正解',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF6C757D),
                                      ),
                                    ),
                                    Text(
                                      '$percentage%',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: percentage >= 70
                                            ? const Color(0xFF28A745)
                                            : percentage >= 50
                                                ? const Color(0xFFFF9800)
                                                : const Color(0xFFDC3545),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}