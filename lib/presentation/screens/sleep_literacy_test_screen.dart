import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_literacy_test_provider.dart';

// 睡眠リテラシーテスト質問画面
class SleepLiteracyTestScreen extends StatefulWidget {
  const SleepLiteracyTestScreen({super.key});

  @override
  State<SleepLiteracyTestScreen> createState() => _SleepLiteracyTestScreenState();
}

class _SleepLiteracyTestScreenState extends State<SleepLiteracyTestScreen> {
  int? selectedAnswer;
  PageController? pageController;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    
    // テストを初期化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepLiteracyTestProvider>().initializeTest();
    });
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SleepLiteracyTestProvider>(
      builder: (context, testProvider, child) {
        if (testProvider.currentTest == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final test = testProvider.currentTest!;
        final currentQuestion = test.currentQuestion;

        if (currentQuestion == null || test.isCompleted) {
          // テスト完了時の処理
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(
              '/sleep-literacy-test-result',
            );
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 現在の質問の回答状況を取得
        selectedAnswer = test.answers[currentQuestion.id];

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.grey),
              onPressed: () => _showExitConfirmDialog(context),
            ),
            title: Text(
              '${test.currentIndex + 1}/10',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                // 進捗バー
                _buildProgressBar(test.currentIndex + 1, 10),
                
                const SizedBox(height: 24),
                
                // 質問内容
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // カテゴリー表示
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            currentQuestion.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 質問文
                        Text(
                          'Q${test.currentIndex + 1}. ${currentQuestion.questionText}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // 選択肢
                        Expanded(
                          child: ListView.builder(
                            itemCount: currentQuestion.options.length,
                            itemBuilder: (context, index) {
                              final isSelected = selectedAnswer == index;
                              final isUnknownOption = index == 4; // 「分からない」
                              
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _buildOptionButton(
                                  option: currentQuestion.options[index],
                                  index: index,
                                  isSelected: isSelected,
                                  isUnknownOption: isUnknownOption,
                                  onTap: () {
                                    setState(() {
                                      selectedAnswer = index;
                                    });
                                    testProvider.answerQuestion(
                                      currentQuestion.id, 
                                      index,
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // ナビゲーションボタン
                _buildNavigationButtons(context, testProvider, test),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: List.generate(total, (index) {
              final isCompleted = index < current;
              final isCurrent = index == current - 1;
              
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < total - 1 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? const Color(0xFF4A90E2)
                        : const Color(0xFFE9ECEF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$current問目 / $total問',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C757D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String option,
    required int index,
    required bool isSelected,
    required bool isUnknownOption,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4A90E2).withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A90E2)
                : isUnknownOption
                    ? const Color(0xFFFF9800)
                    : const Color(0xFFE9ECEF),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 選択インジケーター
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF4A90E2)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4A90E2)
                      : const Color(0xFFCED4DA),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // 選択肢テキスト
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected
                      ? const Color(0xFF4A90E2)
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            
            // 「分からない」アイコン
            if (isUnknownOption)
              const Icon(
                Icons.help_outline,
                size: 18,
                color: Color(0xFFFF9800),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    SleepLiteracyTestProvider testProvider,
    dynamic test,
  ) {
    final canGoBack = test.currentIndex > 0;
    final hasAnswer = selectedAnswer != null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE9ECEF)),
        ),
      ),
      child: Row(
        children: [
          // 戻るボタン
          if (canGoBack)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  testProvider.previousQuestion();
                  setState(() {
                    selectedAnswer = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C757D),
                  side: const BorderSide(color: Color(0xFFCED4DA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '前の問題',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          
          if (canGoBack) const SizedBox(width: 16),
          
          // 次へボタン
          Expanded(
            flex: canGoBack ? 1 : 2,
            child: ElevatedButton(
              onPressed: hasAnswer
                  ? () {
                      testProvider.nextQuestion();
                      setState(() {
                        selectedAnswer = null;
                      });
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasAnswer
                    ? const Color(0xFF4A90E2)
                    : const Color(0xFFCED4DA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                test.currentIndex == test.questions.length - 1 ? '完了' : '次へ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'テストを中断しますか？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            '進捗は保存されません。\n最初からやり直しになります。',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6C757D),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                '続ける',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '中断',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}