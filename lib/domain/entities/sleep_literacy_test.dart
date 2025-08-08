import 'sleep_literacy_question.dart';

// 睡眠リテラシーテストのエンティティ
class SleepLiteracyTest {
  final List<SleepLiteracyQuestion> questions;
  final int currentIndex;
  final Map<int, int> answers; // 質問ID -> 選択肢番号 (0-4, 4は「分からない」)
  final DateTime startTime;
  final DateTime? endTime;

  const SleepLiteracyTest({
    required this.questions,
    this.currentIndex = 0,
    this.answers = const {},
    required this.startTime,
    this.endTime,
  });

  // 現在の質問を取得
  SleepLiteracyQuestion? get currentQuestion {
    if (currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  // テストが完了しているかどうか
  bool get isCompleted => currentIndex >= questions.length;

  // 正解数を計算
  int get score {
    int correctCount = 0;
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final selectedAnswer = entry.value;
      
      final question = questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw StateError('Question not found: $questionId'),
      );
      
      if (selectedAnswer == question.correctAnswer) {
        correctCount++;
      }
    }
    return correctCount;
  }

  // 総回答数
  int get answeredCount => answers.length;

  // 回答率
  double get answerRate => answeredCount / questions.length;

  // 「分からない」の回答数
  int get unknownAnswersCount {
    return answers.values.where((answer) => answer == 4).length; // 4は「分からない」
  }

  // ユーザーの回答をリストとして取得（画面表示用）
  List<int> get userAnswers {
    final List<int> userAnswersList = [];
    for (int i = 0; i < questions.length; i++) {
      final questionId = questions[i].id;
      userAnswersList.add(answers[questionId] ?? -1); // 未回答は-1
    }
    return userAnswersList;
  }

  // テスト時間（分）
  int? get durationMinutes {
    if (endTime != null) {
      return endTime!.difference(startTime).inMinutes;
    }
    return null;
  }

  // カテゴリー別スコア
  Map<String, Map<String, int>> get categoryScores {
    final categoryResults = <String, Map<String, int>>{};
    
    for (final entry in answers.entries) {
      final questionId = entry.key;
      final selectedAnswer = entry.value;
      
      final question = questions.firstWhere(
        (q) => q.id == questionId,
        orElse: () => throw StateError('Question not found: $questionId'),
      );
      
      categoryResults.putIfAbsent(question.category, () => {
        'correct': 0,
        'total': 0,
      });
      
      categoryResults[question.category]!['total'] = 
          categoryResults[question.category]!['total']! + 1;
      
      if (selectedAnswer == question.correctAnswer) {
        categoryResults[question.category]!['correct'] = 
            categoryResults[question.category]!['correct']! + 1;
      }
    }
    
    return categoryResults;
  }

  SleepLiteracyTest copyWith({
    List<SleepLiteracyQuestion>? questions,
    int? currentIndex,
    Map<int, int>? answers,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return SleepLiteracyTest(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // 回答を設定
  SleepLiteracyTest withAnswer(int questionId, int selectedAnswer) {
    final newAnswers = Map<int, int>.from(answers);
    newAnswers[questionId] = selectedAnswer;
    return copyWith(answers: newAnswers);
  }

  // 次の質問に進む
  SleepLiteracyTest nextQuestion() {
    return copyWith(currentIndex: currentIndex + 1);
  }

  // 前の質問に戻る
  SleepLiteracyTest previousQuestion() {
    if (currentIndex > 0) {
      return copyWith(currentIndex: currentIndex - 1);
    }
    return this;
  }

  // テストを完了する
  SleepLiteracyTest complete() {
    return copyWith(
      currentIndex: questions.length,
      endTime: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questions': questions.map((q) => q.toJson()).toList(),
      'currentIndex': currentIndex,
      'answers': answers.map((key, value) => MapEntry(key.toString(), value)),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory SleepLiteracyTest.fromJson(Map<String, dynamic> json) {
    final answersMap = <int, int>{};
    final answersJson = json['answers'] as Map<String, dynamic>;
    for (final entry in answersJson.entries) {
      answersMap[int.parse(entry.key)] = entry.value;
    }

    return SleepLiteracyTest(
      questions: (json['questions'] as List)
          .map((q) => SleepLiteracyQuestion.fromJson(q))
          .toList(),
      currentIndex: json['currentIndex'],
      answers: answersMap,
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
    );
  }

  @override
  String toString() {
    return 'SleepLiteracyTest(currentIndex: $currentIndex, answeredCount: $answeredCount, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepLiteracyTest &&
        other.currentIndex == currentIndex &&
        other.startTime == startTime &&
        other.endTime == endTime;
  }

  @override
  int get hashCode {
    return Object.hash(currentIndex, startTime, endTime);
  }
}