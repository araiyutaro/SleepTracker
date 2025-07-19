// 睡眠リテラシーテストの質問エンティティ
class SleepLiteracyQuestion {
  final int id;
  final String category;
  final String questionText;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  const SleepLiteracyQuestion({
    required this.id,
    required this.category,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  SleepLiteracyQuestion copyWith({
    int? id,
    String? category,
    String? questionText,
    List<String>? options,
    int? correctAnswer,
    String? explanation,
  }) {
    return SleepLiteracyQuestion(
      id: id ?? this.id,
      category: category ?? this.category,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }

  factory SleepLiteracyQuestion.fromJson(Map<String, dynamic> json) {
    return SleepLiteracyQuestion(
      id: json['id'],
      category: json['category'],
      questionText: json['questionText'],
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
    );
  }

  @override
  String toString() {
    return 'SleepLiteracyQuestion(id: $id, category: $category, questionText: $questionText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepLiteracyQuestion &&
        other.id == id &&
        other.category == category &&
        other.questionText == questionText &&
        other.correctAnswer == correctAnswer;
  }

  @override
  int get hashCode {
    return Object.hash(id, category, questionText, correctAnswer);
  }
}