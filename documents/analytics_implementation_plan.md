# データ分析機能実装計画

## フェーズ1: 基本個人分析機能（推奨実装）

### 1. データモデル設計

#### SleepAnalytics エンティティ
```dart
class SleepAnalytics {
  final String userId;
  final DateTime analysisDate;
  final Duration averageSleepDuration;
  final double averageSleepQuality;
  final TimeOfDay averageBedtime;
  final TimeOfDay averageWakeTime;
  final double consistencyScore; // 睡眠リズムの規則性（0-100）
  final Map<String, dynamic> weeklyTrends;
  final List<String> recommendations; // 改善提案
}
```

#### DailyAggregateData エンティティ
```dart
class DailyAggregateData {
  final String userId;
  final DateTime date;
  final Duration? sleepDuration;
  final double? sleepQuality;
  final TimeOfDay? bedtime;
  final TimeOfDay? wakeTime;
  final int? movementCount;
  final Map<String, double>? sleepStagePercentages;
  final DayOfWeek dayType; // 平日 or 休日
}
```

### 2. 分析サービス設計

#### PersonalAnalyticsService
```dart
class PersonalAnalyticsService {
  final SleepRepository sleepRepository;
  final UserRepository userRepository;
  
  // 基本統計（過去30日）
  Future<SleepStatistics> calculateBasicStatistics(String userId);
  
  // 睡眠トレンド（週別推移）
  Future<List<WeeklyTrend>> calculateWeeklyTrends(String userId, int weeks);
  
  // 睡眠パターン分析（平日 vs 休日）
  Future<PatternAnalysis> analyzeWeekdayWeekendPatterns(String userId);
  
  // 改善提案生成
  Future<List<SleepRecommendation>> generateRecommendations(String userId);
  
  // 目標達成度
  Future<GoalProgress> calculateGoalProgress(String userId);
}
```

#### DataAggregationService
```dart
class DataAggregationService {
  final SleepRepository sleepRepository;
  
  // 日次集計（毎日実行）
  Future<void> processDailyAggregation(String userId, DateTime date);
  
  // 週次集計（毎週実行）
  Future<void> processWeeklyAggregation(String userId, DateTime weekStart);
  
  // データクリーニング（外れ値除去）
  List<SleepSession> cleanSleepData(List<SleepSession> sessions);
  
  // 集計データの保存
  Future<void> saveDailyAggregate(DailyAggregateData data);
}
```

### 3. 分析画面設計

#### 個人ダッシュボード画面
```
┌─────────────────────────────────────┐
│ 睡眠分析                            │
├─────────────────────────────────────┤
│ 📊 今週のサマリー                    │
│   平均睡眠時間: 7時間32分            │
│   平均品質: 82%                     │
│   規則性スコア: 75%                  │
├─────────────────────────────────────┤
│ 📈 睡眠時間推移 (過去4週間)          │
│   ┌───┬───┬───┬───┐             │
│   │ W1│ W2│ W3│ W4│             │
│   └───┴───┴───┴───┘             │
├─────────────────────────────────────┤
│ 💡 改善提案                         │
│   • 就寝時刻を30分早めることを       │
│     おすすめします                   │
│   • 週末の寝だめを控えましょう       │
├─────────────────────────────────────┤
│ 🎯 目標達成度                       │
│   目標睡眠時間達成: 6/7日            │
│   理想就寝時刻達成: 4/7日            │
└─────────────────────────────────────┘
```

#### 詳細分析画面
```
┌─────────────────────────────────────┐
│ 詳細分析                            │
├─────────────────────────────────────┤
│ 📅 期間選択: [過去30日 ▼]            │
├─────────────────────────────────────┤
│ 🔍 平日 vs 休日比較                  │
│   平日平均: 7時間15分 (品質: 78%)    │
│   休日平均: 8時間45分 (品質: 85%)    │
│   社会的ジェットラグ: 1時間30分      │
├─────────────────────────────────────┤
│ 📊 睡眠段階分析                     │
│   深い睡眠: 22% (理想: 20-25%)      │
│   浅い睡眠: 55% (理想: 45-55%)      │
│   REM睡眠: 18% (理想: 20-25%)       │
├─────────────────────────────────────┤
│ 🔗 相関分析                         │
│   カフェイン摂取 ↔ 寝つき: -0.3     │
│   運動実施 ↔ 睡眠品質: +0.5         │
│   スマホ利用 ↔ 入眠時間: -0.4       │
└─────────────────────────────────────┘
```

### 4. 実装優先順位

#### 高優先度（最初の2週間）
1. **DailyAggregateData モデル**: 日次集計データの保存
2. **基本統計計算**: 平均睡眠時間、品質、規則性スコア
3. **週間推移グラフ**: 過去4週間の睡眠時間推移
4. **簡単な改善提案**: ルールベースの基本的なアドバイス

#### 中優先度（3-4週間目）
1. **平日休日比較**: 社会的ジェットラグの計算
2. **目標達成度**: ユーザー設定目標との比較
3. **睡眠段階分析**: センサーデータからの詳細分析
4. **期間選択機能**: 7日、30日、90日の切り替え

#### 低優先度（将来実装）
1. **相関分析**: 生活習慣と睡眠の関係性
2. **予測機能**: AIによる睡眠品質予測
3. **詳細レポート**: PDF出力機能
4. **グループ比較**: 同年代・同職業との比較

### 5. データベース拡張

#### 日次集計テーブル
```sql
CREATE TABLE daily_sleep_aggregates (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date TEXT NOT NULL,
    sleep_duration_minutes INTEGER,
    sleep_quality REAL,
    bedtime_hour INTEGER,
    bedtime_minute INTEGER,
    wake_time_hour INTEGER,
    wake_time_minute INTEGER,
    movement_count INTEGER,
    deep_sleep_percentage REAL,
    light_sleep_percentage REAL,
    rem_sleep_percentage REAL,
    awake_percentage REAL,
    day_type TEXT, -- 'weekday' or 'weekend'
    created_at INTEGER NOT NULL,
    UNIQUE(user_id, date)
);
```

#### 週次集計テーブル
```sql
CREATE TABLE weekly_sleep_aggregates (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    week_start_date TEXT NOT NULL,
    avg_sleep_duration REAL,
    avg_sleep_quality REAL,
    consistency_score REAL,
    weekday_avg_duration REAL,
    weekend_avg_duration REAL,
    social_jetlag_minutes INTEGER,
    created_at INTEGER NOT NULL,
    UNIQUE(user_id, week_start_date)
);
```

### 6. 分析アルゴリズム例

#### 規則性スコア計算
```dart
double calculateConsistencyScore(List<DailyAggregateData> dailyData) {
  if (dailyData.length < 7) return 0.0;
  
  // 就寝時刻の標準偏差を計算
  final bedtimes = dailyData
      .where((d) => d.bedtime != null)
      .map((d) => d.bedtime!.hour * 60 + d.bedtime!.minute)
      .toList();
  
  if (bedtimes.isEmpty) return 0.0;
  
  final mean = bedtimes.reduce((a, b) => a + b) / bedtimes.length;
  final variance = bedtimes
      .map((time) => pow(time - mean, 2))
      .reduce((a, b) => a + b) / bedtimes.length;
  final standardDeviation = sqrt(variance);
  
  // 標準偏差が小さいほど規則的（最大120分で正規化）
  return max(0.0, (120 - standardDeviation) / 120 * 100);
}
```

#### 改善提案生成
```dart
List<SleepRecommendation> generateBasicRecommendations(
  SleepStatistics stats,
  UserProfile profile,
) {
  final recommendations = <SleepRecommendation>[];
  
  // 睡眠時間不足の場合
  if (stats.averageSleepDuration < Duration(hours: 7)) {
    recommendations.add(SleepRecommendation(
      type: RecommendationType.sleepDuration,
      title: '睡眠時間を増やしましょう',
      description: '理想的な睡眠時間は7-9時間です。就寝時刻を30分早めることをおすすめします。',
      priority: Priority.high,
    ));
  }
  
  // 規則性が低い場合
  if (stats.consistencyScore < 70) {
    recommendations.add(SleepRecommendation(
      type: RecommendationType.consistency,
      title: '睡眠リズムを整えましょう',
      description: '毎日同じ時間に寝起きすることで、睡眠の質が向上します。',
      priority: Priority.medium,
    ));
  }
  
  // スマホ利用時間が長い場合
  if (profile.phoneUsageTime == '1時間～2時間' || 
      profile.phoneUsageTime == '2時間以上') {
    recommendations.add(SleepRecommendation(
      type: RecommendationType.phoneUsage,
      title: '就寝前のスマホ時間を減らしましょう',
      description: 'ブルーライトが睡眠の質に影響する可能性があります。',
      priority: Priority.medium,
    ));
  }
  
  return recommendations;
}
```

### 7. 初期実装のメリット

1. **ユーザーエンゲージメント向上**: 自分の睡眠データを可視化することで継続利用を促進
2. **科学的根拠**: 実際のデータに基づいた改善提案でユーザーの信頼獲得
3. **差別化**: 単純な記録アプリから分析アプリへの進化
4. **データ品質向上**: 分析結果がおかしい場合、データ収集の問題を早期発見

### 8. 注意点

1. **計算負荷**: 大量のデータ処理は非同期処理で実装
2. **データ欠損**: 記録されていない日の扱い方を明確化
3. **プライバシー**: 個人データの分析結果は端末内で完結
4. **精度**: 初期は簡単な統計から始めて段階的に精度向上