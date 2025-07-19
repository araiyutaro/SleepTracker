import 'package:flutter/foundation.dart';
import '../../domain/entities/sleep_literacy_test.dart';
import '../../domain/entities/sleep_literacy_question.dart';
import '../../data/datasources/sleep_literacy_questions_data.dart';
import '../../services/analytics_service.dart';

// 睡眠リテラシーテストの状態管理プロバイダー
class SleepLiteracyTestProvider extends ChangeNotifier {
  SleepLiteracyTest? _currentTest;
  bool _isLoading = false;
  String? _error;

  // Getters
  SleepLiteracyTest? get currentTest => _currentTest;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // テストを初期化
  Future<void> initializeTest() async {
    if (_currentTest != null) return; // 既に初期化済みの場合はスキップ
    
    _setLoading(true);
    _error = null;

    try {
      // 質問データを取得（シャッフルしない固定順序）
      final questions = SleepLiteracyQuestionsData.questions;
      
      // テストオブジェクトを作成
      _currentTest = SleepLiteracyTest(
        questions: questions,
        startTime: DateTime.now(),
      );

      // アナリティクスイベントを送信
      await AnalyticsService().logCustomEvent(
        'sleep_literacy_test_started',
        parameters: {
          'question_count': questions.length,
          'start_time': DateTime.now().millisecondsSinceEpoch,
        },
      );

      debugPrint('Sleep literacy test initialized with ${questions.length} questions');
    } catch (e) {
      _error = 'テストの初期化に失敗しました: $e';
      debugPrint('Error initializing sleep literacy test: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 回答を設定
  void answerQuestion(int questionId, int selectedAnswer) {
    if (_currentTest == null) return;

    try {
      final updatedTest = _currentTest!.withAnswer(questionId, selectedAnswer);
      _currentTest = updatedTest;

      // アナリティクスイベントを送信
      final question = _currentTest!.questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw StateError('Question not found: $questionId'),
      );

      AnalyticsService().logCustomEvent(
        'sleep_literacy_question_answered',
        parameters: {
          'question_id': questionId,
          'question_category': question.category,
          'selected_answer': selectedAnswer,
          'is_correct': selectedAnswer == question.correctAnswer,
          'is_unknown': selectedAnswer == 4, // 「分からない」の場合
          'question_index': _currentTest!.currentIndex,
        },
      );

      notifyListeners();
      debugPrint('Question $questionId answered with option $selectedAnswer');
    } catch (e) {
      _error = '回答の保存に失敗しました: $e';
      debugPrint('Error answering question: $e');
      notifyListeners();
    }
  }

  // 次の質問に進む
  void nextQuestion() {
    if (_currentTest == null) return;

    try {
      final updatedTest = _currentTest!.nextQuestion();
      _currentTest = updatedTest;

      // テスト完了チェック
      if (_currentTest!.isCompleted) {
        _completeTest();
      }

      notifyListeners();
      debugPrint('Moved to next question. Current index: ${_currentTest!.currentIndex}');
    } catch (e) {
      _error = '次の質問への移動に失敗しました: $e';
      debugPrint('Error moving to next question: $e');
      notifyListeners();
    }
  }

  // 前の質問に戻る
  void previousQuestion() {
    if (_currentTest == null) return;

    try {
      final updatedTest = _currentTest!.previousQuestion();
      _currentTest = updatedTest;
      notifyListeners();
      debugPrint('Moved to previous question. Current index: ${_currentTest!.currentIndex}');
    } catch (e) {
      _error = '前の質問への移動に失敗しました: $e';
      debugPrint('Error moving to previous question: $e');
      notifyListeners();
    }
  }

  // テストを完了
  void _completeTest() {
    if (_currentTest == null) return;

    try {
      final completedTest = _currentTest!.complete();
      _currentTest = completedTest;

      // アナリティクスイベントを送信
      AnalyticsService().logCustomEvent(
        'sleep_literacy_test_completed',
        parameters: {
          'score': _currentTest!.score,
          'total_questions': _currentTest!.questions.length,
          'correct_percentage': (_currentTest!.score / _currentTest!.questions.length * 100).round(),
          'answered_count': _currentTest!.answeredCount,
          'unknown_answers_count': _currentTest!.unknownAnswersCount,
          'duration_minutes': _currentTest!.durationMinutes ?? 0,
          'category_scores': _currentTest!.categoryScores,
        },
      );

      debugPrint('Sleep literacy test completed. Score: ${_currentTest!.score}/10');
    } catch (e) {
      _error = 'テストの完了処理に失敗しました: $e';
      debugPrint('Error completing test: $e');
    }
  }

  // テストをリセット
  void resetTest() {
    _currentTest = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('Sleep literacy test reset');
  }

  // 特定の質問にジャンプ（デバッグ用）
  void jumpToQuestion(int index) {
    if (_currentTest == null || index < 0 || index >= _currentTest!.questions.length) {
      return;
    }

    try {
      final updatedTest = _currentTest!.copyWith(currentIndex: index);
      _currentTest = updatedTest;
      notifyListeners();
      debugPrint('Jumped to question index: $index');
    } catch (e) {
      _error = '質問への移動に失敗しました: $e';
      debugPrint('Error jumping to question: $e');
      notifyListeners();
    }
  }

  // 進捗情報を取得
  Map<String, dynamic> getProgress() {
    if (_currentTest == null) {
      return {
        'current': 0,
        'total': 0,
        'percentage': 0.0,
        'answered': 0,
      };
    }

    return {
      'current': _currentTest!.currentIndex + 1,
      'total': _currentTest!.questions.length,
      'percentage': (_currentTest!.currentIndex + 1) / _currentTest!.questions.length,
      'answered': _currentTest!.answeredCount,
    };
  }

  // テスト統計を取得
  Map<String, dynamic> getTestStatistics() {
    if (_currentTest == null) {
      return {};
    }

    return {
      'score': _currentTest!.score,
      'totalQuestions': _currentTest!.questions.length,
      'correctPercentage': (_currentTest!.score / _currentTest!.questions.length * 100).round(),
      'answeredCount': _currentTest!.answeredCount,
      'unknownAnswersCount': _currentTest!.unknownAnswersCount,
      'durationMinutes': _currentTest!.durationMinutes,
      'categoryScores': _currentTest!.categoryScores,
      'isCompleted': _currentTest!.isCompleted,
    };
  }

  // カテゴリー別の詳細統計を取得
  Map<String, Map<String, dynamic>> getCategoryDetails() {
    if (_currentTest == null) return {};

    final categoryDetails = <String, Map<String, dynamic>>{};
    
    for (final category in SleepLiteracyQuestionsData.getAllCategories()) {
      final categoryQuestions = _currentTest!.questions
          .where((q) => q.category == category)
          .toList();
      
      int correctCount = 0;
      int answeredCount = 0;
      int unknownCount = 0;
      
      for (final question in categoryQuestions) {
        final answer = _currentTest!.answers[question.id];
        if (answer != null) {
          answeredCount++;
          if (answer == question.correctAnswer) {
            correctCount++;
          } else if (answer == 4) { // 「分からない」
            unknownCount++;
          }
        }
      }
      
      categoryDetails[category] = {
        'totalQuestions': categoryQuestions.length,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'unknownCount': unknownCount,
        'percentage': answeredCount > 0 ? (correctCount / answeredCount * 100).round() : 0,
      };
    }
    
    return categoryDetails;
  }

  // エラーをクリア
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // プライベートメソッド
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    // リソースのクリーンアップ
    super.dispose();
  }
}