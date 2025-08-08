import '../../domain/entities/sleep_literacy_question.dart';

// 睡眠リテラシーテストの質問データ
class SleepLiteracyQuestionsData {
  static const List<SleepLiteracyQuestion> questions = [
    // 基本的な睡眠知識 (3問)
    SleepLiteracyQuestion(
      id: 1,
      category: '基本的な睡眠知識',
      questionText: '一般的に、健康な成人に推奨される一晩の睡眠時間はどれくらいですか？',
      options: [
        '4〜5時間',
        '5〜6時間',
        '7〜9時間',
        '10時間以上',
        '分からない',
      ],
      correctAnswer: 2, // 7〜9時間
      explanation: '健康な成人には、一晩に7〜9時間の睡眠が推奨されています。',
    ),
    
    SleepLiteracyQuestion(
      id: 2,
      category: '基本的な睡眠知識',
      questionText: '夜間にスマートフォンの画面を見る際、睡眠に最も大きな影響を与えるとされる主な要因は何ですか？',
      options: [
        '画面から放出される電磁波が、夢の内容に影響を与えるため。',
        '画面の「ブルーライト」が、睡眠を促すホルモン（メラトニン）の分泌を抑制するため。',
        'スマートフォンを操作することで指の筋肉が疲労し、寝つきが悪くなるため。',
        'SNSの「いいね」の数が気になり、脳がリラックスできなくなるため。',
        '分からない',
      ],
      correctAnswer: 1, // ブルーライト
      explanation: 'ブルーライトは、体内時計を調整し自然な眠りを誘うメラトニンの分泌を抑制する作用があるため、夜間のスマートフォン利用は寝つきを悪くする主な原因となります。',
    ),
    
    SleepLiteracyQuestion(
      id: 3,
      category: '基本的な睡眠知識',
      questionText: '就寝前のカフェイン摂取について、最も適切な説明はどれですか？',
      options: [
        '就寝直前に飲んでも、ほとんどの人は影響を受けない。',
        'カフェインは覚醒作用があるが、その効果は1〜2時間でなくなる。',
        '温かいコーヒーであれば、リラックス効果でむしろ寝つきが良くなる。',
        'カフェインの覚醒効果は数時間続くため、少なくとも就寝の数時間前からは避けるべきである。',
        '分からない',
      ],
      correctAnswer: 3, // 数時間前から避けるべき
      explanation: 'カフェインの覚醒作用は個人差がありますが、一般的に摂取後数時間持続するため、安眠のためには午後以降の摂取を控えることが望ましいとされています。',
    ),

    // 睡眠に影響する要因 (2問)
    SleepLiteracyQuestion(
      id: 4,
      category: '睡眠に影響する要因',
      questionText: '就寝前のアルコール（お酒）の摂取が睡眠に与える影響として、最も正確なものはどれですか？',
      options: [
        '寝つきを良くする効果があるため、質の良い睡眠のための優れた方法である。',
        '睡眠の質には全く影響を与えない。',
        '寝つきは良くなることがあるが、夜中に目が覚めやすくなり、睡眠全体の質を低下させる。',
        'アルコールを飲むと、必ず悪夢を見るようになる。',
        '分からない',
      ],
      correctAnswer: 2, // 質を低下させる
      explanation: 'アルコールは入眠を助けるように感じられることがありますが、睡眠の後半部分で眠りを浅くし、中途覚醒を増やす原因となります。',
    ),
    
    SleepLiteracyQuestion(
      id: 5,
      category: '睡眠に影響する要因',
      questionText: '夜間の不必要なスマートフォン利用を減らすための戦略として、行動科学的に最も効果が期待できるものはどれですか？',
      options: [
        '「夜はスマホを見ない」という強い意志を持つ。',
        'スマートフォンをマナーモードに設定して枕元に置く。',
        'スマートフォンを寝室の外や、ベッドから手の届かない場所で充電する。',
        '就寝前に、面白い動画を一つだけ見るようにする。',
        '分からない',
      ],
      correctAnswer: 2, // 物理的に遠ざける
      explanation: '意志の力だけに頼るのではなく、スマートフォンを物理的に遠ざけるという「環境」を変えるアプローチは、行動を変える上で非常に効果的な戦略（ナッジ）です。',
    ),

    // 睡眠習慣と環境 (3問)
    SleepLiteracyQuestion(
      id: 6,
      category: '睡眠習慣と環境',
      questionText: '日中の昼寝について、最も望ましい習慣はどれですか？',
      options: [
        '毎日3時間以上、ぐっすり昼寝をする。',
        '夜の睡眠に影響しないよう、昼寝は完全に避けるべきである。',
        '夕方（午後4時以降など）に1時間ほど昼寝をして、夜の活動に備える。',
        '午後早い時間に、30分以内の短い昼寝をする。',
        '分からない',
      ],
      correctAnswer: 3, // 30分以内の短い昼寝
      explanation: '長い昼寝や午後の遅い時間帯の昼寝は、夜間の睡眠を妨げる可能性があります。午後3時までに30分以内の短い昼寝をとることが推奨されます。',
    ),
    
    SleepLiteracyQuestion(
      id: 7,
      category: '睡眠習慣と環境',
      questionText: '運動習慣と睡眠の関係について、最も適切なものはどれですか？',
      options: [
        '睡眠の質を高めるためには、就寝直前に激しい運動をするのが最も効果的である。',
        '日中の定期的な運動は睡眠の質を高めるが、就寝直前の激しい運動は避けるべきである。',
        '運動は体を疲れさせるため、どのような時間帯に行っても睡眠には悪影響しかない。',
        '運動と睡眠の質には、科学的な関連性はない。',
        '分からない',
      ],
      correctAnswer: 1, // 日中の運動は良いが就寝直前は避ける
      explanation: '日中の定期的な運動は睡眠の質を向上させますが、就寝直前の激しい運動は体を覚醒させてしまうため、避けるのが望ましいです。',
    ),
    
    SleepLiteracyQuestion(
      id: 8,
      category: '睡眠習慣と環境',
      questionText: '質の良い睡眠を得るための寝室の環境として、最も理想的なものはどれですか？',
      options: [
        '明るく、暖かく、静かな環境。',
        '適度に涼しく、暗く、静かな環境。',
        'テレビや音楽をつけたままの、賑やかな環境。',
        '自分の好きな香りのアロマを強く焚いた、暖かい環境。',
        '分からない',
      ],
      correctAnswer: 1, // 涼しく、暗く、静か
      explanation: '体温が少し下がることで眠りに入りやすくなるため、寝室は涼しく、光や音の刺激がない暗くて静かな環境が理想的です。',
    ),

    // 睡眠改善と治療 (2問)
    SleepLiteracyQuestion(
      id: 9,
      category: '睡眠改善と治療',
      questionText: '平日に睡眠不足になった場合、週末の過ごし方として最も推奨されるものはどれですか？',
      options: [
        '週末は昼過ぎまで寝だめをして、睡眠負債を完全に返済する。',
        '平日とできるだけ同じ時間に起き、もし眠ければ日中に短い昼寝をする。',
        '週末は夜更かしをして、友人との交流や趣味の時間を優先する。',
        '週末は一切眠らずに活動し、次の月曜日に備える。',
        '分からない',
      ],
      correctAnswer: 1, // 同じ時間に起きる
      explanation: '週末に大幅に寝坊すると体内時計が乱れてしまいます。睡眠リズムを保つために、起床時間はできるだけ一定にすることが重要です。',
    ),
    
    SleepLiteracyQuestion(
      id: 10,
      category: '睡眠改善と治療',
      questionText: '薬を使わずに不眠症を改善するための、専門的な治療法として有効性が示されているものは次のうちどれですか？',
      options: [
        '毎晩、就寝前に熱いお風呂に1時間以上入る温熱療法。',
        '睡眠に関する考え方や行動の癖を修正していく、認知行動療法（CBT-I）。',
        '寝室で激しい運動を行うことで体を疲れさせる、睡眠導入運動法。',
        '毎晩、睡眠導入効果のある音楽を大音量で聴く音楽療法。',
        '分からない',
      ],
      correctAnswer: 1, // 認知行動療法
      explanation: '認知行動療法（CBT-I）は、睡眠に対する不適切な考えや習慣を修正する心理療法で、薬物を使わない不眠症治療の第一選択として推奨されています。',
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

  // 睡眠リテラシーレベルの評価
  static String getSleepLiteracyLevel(int correctAnswers) {
    if (correctAnswers >= 8) {
      return '睡眠リテラシーが高い';
    } else if (correctAnswers >= 5) {
      return '基本的な睡眠リテラシーがある';
    } else {
      return '睡眠リテラシーに改善の余地がある';
    }
  }

  // 睡眠リテラシーレベルの詳細説明
  static String getSleepLiteracyDescription(int correctAnswers) {
    if (correctAnswers >= 8) {
      return '睡眠に関する基本的な知識と、スマートフォン利用などの現代的な課題が睡眠に与える影響について、正確に理解している状態。健康的な睡眠習慣を自己管理できる可能性が高い。';
    } else if (correctAnswers >= 5) {
      return '基本的な知識はあるものの、いくつかの点で誤解や知識不足が見られる状態。特定の情報提供や教育によって、行動変容が期待できる層。';
    } else {
      return '睡眠に関する誤解が多く、健康的な睡眠習慣を実践する上での知識が不足している状態。より積極的な教育的介入が必要と考えられる。';
    }
  }

  // 選択肢の文字ラベル（A, B, C, D, E）を取得
  static String getOptionLabel(int index) {
    const labels = ['A', 'B', 'C', 'D', 'E'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '';
  }
}