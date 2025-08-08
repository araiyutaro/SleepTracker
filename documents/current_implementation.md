# 睡眠記録アプリ - 現状実装仕様書

## 概要
ポケモンスリープライクな軽量睡眠記録アプリ。Flutter/Dartで開発され、iOS・Android両対応。ゲーミフィケーション要素とセンサー分析機能を搭載。

## 実装済み機能

### 1. 基本睡眠記録機能
- **睡眠開始/終了の記録**
  - ワンタップで睡眠記録開始・終了
  - リアルタイム睡眠時間表示
  - SQLiteによるローカルデータ保存

- **履歴表示**
  - 過去7日間の睡眠記録表示
  - 睡眠時間・品質スコア・日付の表示
  - カレンダービューでの月間表示

### 2. センサー分析機能
- **加速度センサー監視**
  - バックグラウンドでの動作検知
  - 睡眠中の体動データ収集
  - 権限管理（デバイス設定への誘導含む）

- **睡眠ステージ分析**
  - 深い睡眠、浅い睡眠、REM睡眠、覚醒の判定
  - 動作頻度・強度による品質スコア算出
  - 睡眠品質の可視化

### 3. 統計・分析機能
- **週間統計**
  - 平均睡眠時間
  - 平均品質スコア
  - 週間の睡眠パターン分析

- **データ可視化**
  - fl_chartによるグラフ表示
  - 睡眠時間の推移
  - 品質スコアの変化

### 4. ゲーミフィケーション機能
- **ポイントシステム**
  - 睡眠記録でポイント獲得
  - 品質に応じたボーナスポイント
  - レベルシステム（500ポイント/レベル）

- **アチーブメントシステム**
  - 初回記録、連続記録、早起き等の実績
  - 各実績にポイント報酬
  - 進捗状況の可視化

### 5. ユーザー設定機能
- **目標設定**
  - 目標睡眠時間（4-12時間）
  - 目標就寝時刻
  - 目標起床時刻

- **プロフィール管理**
  - ユーザーデータの永続化
  - 設定の即座反映

### 6. 通知システム
- **就寝リマインダー**
  - 設定時刻の15-60分前に通知
  - カスタマイズ可能な通知時間
  - 毎日の自動スケジューリング

- **起床アラーム**
  - 目標起床時刻でのアラーム
  - 有効/無効の切り替え可能
  - フルスクリーン表示とバイブレーション

- **睡眠品質通知**
  - 睡眠記録終了時の自動通知
  - 品質スコアに応じたメッセージ
  - 即座のフィードバック提供

- **週間レポート**
  - 毎週日曜日の定期通知
  - 1週間の睡眠データサマリー
  - 継続利用の促進

## 技術アーキテクチャ

### アーキテクチャパターン
- **Clean Architecture**採用
- Domain / Data / Presentation層の分離
- Repositoryパターンによるデータ抽象化

### 主要技術スタック
- **フレームワーク**: Flutter 3.x
- **状態管理**: Provider
- **ローカルDB**: SQLite (sqflite)
- **センサー**: sensors_plus
- **通知**: flutter_local_notifications + timezone
- **グラフ**: fl_chart
- **カレンダー**: table_calendar

### データ構造

#### SleepSession（睡眠セッション）
```dart
class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;
  final double? qualityScore;
  final List<MovementData> movements;
  final SleepStageData? sleepStages;
  final DateTime createdAt;
}
```

#### UserProfile（ユーザープロフィール）
```dart
class UserProfile {
  final String id;
  final double targetSleepHours;
  final TimeOfDay targetBedtime;
  final TimeOfDay targetWakeTime;
  final int points;
  final List<Achievement> achievements;
  final NotificationSettings notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### NotificationSettings（通知設定）
```dart
class NotificationSettings {
  final bool bedtimeReminderEnabled;
  final int bedtimeReminderMinutes;
  final bool wakeUpAlarmEnabled;
  final bool sleepQualityNotificationEnabled;
  final bool weeklyReportEnabled;
}
```

## データベーススキーマ

### sleep_records テーブル
- id (TEXT PRIMARY KEY)
- start_time (INTEGER)
- end_time (INTEGER)
- duration_minutes (INTEGER)
- quality_score (REAL)
- movements_json (TEXT)
- sleep_stages_json (TEXT)
- created_at (INTEGER)

### user_profiles テーブル
- id (TEXT PRIMARY KEY)
- target_sleep_hours (REAL)
- target_bedtime (TEXT)
- target_wake_time (TEXT)
- points (INTEGER)
- achievements_json (TEXT)
- notification_settings_json (TEXT)
- created_at (INTEGER)
- updated_at (INTEGER)

## 権限要件

### Android
- android.permission.WAKE_LOCK
- android.permission.RECEIVE_BOOT_COMPLETED
- android.permission.VIBRATE
- android.permission.USE_EXACT_ALARM
- android.permission.SCHEDULE_EXACT_ALARM
- android.permission.POST_NOTIFICATIONS
- minSdkVersion: 19

### iOS
- NSMotionUsageDescription
- 通知権限（アラート・バッジ・サウンド）

## UI/UX特徴

### デザインテーマ
- マテリアルデザイン準拠
- ライト・ダークテーマ対応
- 日本語ローカライゼーション

### 主要画面
1. **ホーム画面** - 睡眠記録開始/終了ボタン
2. **履歴画面** - 過去の睡眠記録一覧
3. **統計画面** - グラフとデータ分析
4. **プロフィール画面** - ユーザー情報とアチーブメント
5. **通知設定画面** - 通知の詳細設定

### ナビゲーション
- BottomNavigationBarによるタブ切り替え
- 直感的なアイコンとラベル
- 一貫したUI/UX体験

## パフォーマンス最適化

### センサー管理
- 睡眠記録中のみセンサー有効化
- バックグラウンド処理の最適化
- バッテリー消費の最小化

### データ管理
- SQLiteインデックス最適化
- JSONシリアライゼーションによる複雑データ保存
- メモリ効率的なデータ処理

## セキュリティ・プライバシー

### データ保護
- 全データローカル保存
- 外部サーバーへの送信なし
- ユーザープライバシー完全保護

### 権限管理
- 必要最小限の権限要求
- 明確な権限説明
- ユーザー主導の権限制御

## 今後の拡張予定

### 実装予定機能
1. **データエクスポート機能** - CSV/JSON形式での出力
2. **スマートアラーム** - 浅い睡眠時の起床
3. **ウィジェット対応** - ホーム画面での情報表示
4. **バックアップ・復元機能** - データの安全性向上

### 技術的改善
- より高度な睡眠分析アルゴリズム
- 機械学習による個人化
- パフォーマンス最適化
- アクセシビリティ対応強化

## バージョン情報
- **現在バージョン**: 1.0.0+1
- **Flutter SDK**: >=2.19.4 <3.0.0
- **最終更新**: 2025年7月6日