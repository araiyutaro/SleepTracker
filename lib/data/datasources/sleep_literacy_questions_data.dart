import '../../domain/entities/sleep_literacy_question.dart';

// 睡眠リテラシーテストの質問データ
class SleepLiteracyQuestionsData {
  static const List<SleepLiteracyQuestion> questions = [
    // 睡眠の基礎知識 (3問)
    SleepLiteracyQuestion(
      id: 1,
      category: '睡眠の基礎知識',
      questionText: '一晩の睡眠中、レム睡眠とノンレム睡眠のサイクルは約何分で繰り返されますか？',
      options: [
        '約30分',
        '約60分',
        '約90分',
        '約120分',
        '分からない',
      ],
      correctAnswer: 2, // 約90分
      explanation: 'レム睡眠とノンレム睡眠は約90分のサイクルで繰り返され、一晩で4-6回のサイクルが発生します。',
    ),
    
    SleepLiteracyQuestion(
      id: 2,
      category: '睡眠の基礎知識',
      questionText: '成人の理想的な睡眠時間は一般的に何時間とされていますか？',
      options: [
        '5-6時間',
        '7-9時間',
        '10-12時間',
        '人により大きく異なる',
        '分からない',
      ],
      correctAnswer: 1, // 7-9時間
      explanation: '成人の理想的な睡眠時間は7-9時間とされており、これは多くの睡眠研究で推奨される範囲です。',
    ),
    
    SleepLiteracyQuestion(
      id: 3,
      category: '睡眠の基礎知識',
      questionText: 'レム睡眠中に最も活発に行われることは何ですか？',
      options: [
        '成長ホルモンの分泌',
        '記憶の整理・定着',
        '体温調節',
        '免疫機能の強化',
        '分からない',
      ],
      correctAnswer: 1, // 記憶の整理・定着
      explanation: 'レム睡眠中は脳が活発に働き、特に記憶の整理や定着、学習内容の処理が行われます。',
    ),

    // 睡眠の誤解と真実 (2問)
    SleepLiteracyQuestion(
      id: 4,
      category: '睡眠の誤解と真実',
      questionText: '平日の睡眠不足は週末の寝だめで完全に解消できる。この説明は？',
      options: [
        '完全に正しい',
        'ある程度正しい',
        'ほとんど正しくない',
        '個人差が大きい',
        '分からない',
      ],
      correctAnswer: 2, // ほとんど正しくない
      explanation: '睡眠負債は寝だめでは完全に解消されません。規則正しい睡眠習慣の方が重要です。',
    ),
    
    SleepLiteracyQuestion(
      id: 5,
      category: '睡眠の誤解と真実',
      questionText: '年齢を重ねると必要な睡眠時間は減少する。この説明は？',
      options: [
        '正しい',
        '部分的に正しい',
        '間違っている',
        '性別により異なる',
        '分からない',
      ],
      correctAnswer: 1, // 部分的に正しい
      explanation: '高齢者は睡眠時間が短くなる傾向がありますが、質の良い睡眠は引き続き重要です。',
    ),

    // 睡眠衛生 (2問)
    SleepLiteracyQuestion(
      id: 6,
      category: '睡眠衛生',
      questionText: '就寝前のスマートフォン使用が睡眠に与える主な悪影響は？',
      options: [
        '電磁波による脳への影響',
        'ブルーライトによるメラトニン分泌抑制',
        '目の疲れによる入眠困難',
        '通知音による睡眠中断',
        '分からない',
      ],
      correctAnswer: 1, // ブルーライトによるメラトニン分泌抑制
      explanation: 'ブルーライトは体内時計を調節するメラトニンの分泌を抑制し、入眠を妨げます。',
    ),
    
    SleepLiteracyQuestion(
      id: 7,
      category: '睡眠衛生',
      questionText: '良質な睡眠のための寝室の理想的な温度は？',
      options: [
        '15-17度',
        '18-20度',
        '21-23度',
        '24-26度',
        '分からない',
      ],
      correctAnswer: 1, // 18-20度
      explanation: '寝室の理想的な温度は18-20度とされており、体温の自然な低下を促進します。',
    ),

    // 睡眠と健康 (2問)
    SleepLiteracyQuestion(
      id: 8,
      category: '睡眠と健康',
      questionText: '慢性的な睡眠不足が最も関連性の高い健康問題は？',
      options: [
        '風邪・インフルエンザ',
        '糖尿病・肥満',
        '腰痛・肩こり',
        '目の疲れ',
        '分からない',
      ],
      correctAnswer: 1, // 糖尿病・肥満
      explanation: '睡眠不足は糖代謝や食欲調節ホルモンに影響し、糖尿病や肥満のリスクを高めます。',
    ),
    
    SleepLiteracyQuestion(
      id: 9,
      category: '睡眠と健康',
      questionText: '睡眠中に分泌される主要な成長ホルモンの役割は？',
      options: [
        '脳の記憶を整理する',
        '体の修復・再生を促進する',
        '体温を調節する',
        'ストレスを軽減する',
        '分からない',
      ],
      correctAnswer: 1, // 体の修復・再生を促進する
      explanation: '成長ホルモンは睡眠中に分泌され、組織の修復や再生、免疫機能の強化を行います。',
    ),

    // 個人差の理解 (1問)
    SleepLiteracyQuestion(
      id: 10,
      category: '個人差の理解',
      questionText: 'クロノタイプ（朝型・夜型）は主に何によって決まりますか？',
      options: [
        '生活習慣',
        '遺伝的要因',
        '職業',
        '年齢',
        '分からない',
      ],
      correctAnswer: 1, // 遺伝的要因
      explanation: 'クロノタイプは主に遺伝的要因によって決まり、個人の体内時計の自然なリズムを反映します。',
    ),
  ];

  // カテゴリー別の質問数を取得
  static Map<String, int> getCategoryQuestionCounts() {
    final categoryCount = <String, int>{};
    for (final question in questions) {
      categoryCount[question.category] = 
          (categoryCount[question.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  // 特定のカテゴリーの質問を取得
  static List<SleepLiteracyQuestion> getQuestionsByCategory(String category) {
    return questions.where((q) => q.category == category).toList();
  }

  // 全カテゴリーのリストを取得
  static List<String> getAllCategories() {
    return questions.map((q) => q.category).toSet().toList();
  }

  // 質問をシャッフルして取得（テスト時の順序をランダム化）
  static List<SleepLiteracyQuestion> getShuffledQuestions() {
    final shuffled = List<SleepLiteracyQuestion>.from(questions);
    shuffled.shuffle();
    return shuffled;
  }

  // IDで特定の質問を取得
  static SleepLiteracyQuestion? getQuestionById(int id) {
    try {
      return questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }
}