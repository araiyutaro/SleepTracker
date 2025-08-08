# 開発計画書

## 1. プロジェクト構成

### 1.1 ディレクトリ構造
```
sleep/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── themes/
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   ├── repositories/
│   │   └── datasources/
│   ├── domain/
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── presentation/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── providers/
│   └── services/
│       ├── notification_service.dart
│       ├── sensor_service.dart
│       └── storage_service.dart
├── assets/
│   ├── images/
│   ├── animations/
│   └── sounds/
├── test/
└── docs/
```

### 1.2 アーキテクチャ
- **Clean Architecture**を採用
- **Provider**または**Riverpod**で状態管理
- **Repository Pattern**でデータアクセス層を抽象化

## 2. 開発スケジュール

### Week 1-2: 基盤構築
- [ ] プロジェクト初期設定
- [ ] 必要なパッケージの追加
- [ ] 基本的なディレクトリ構造の作成
- [ ] テーマ・スタイルの定義
- [ ] データモデルの実装

### Week 3-4: MVP機能実装
- [ ] 睡眠記録の開始/終了機能
- [ ] ローカルデータベースの実装
- [ ] 基本的なホーム画面UI
- [ ] 睡眠履歴の保存・読み込み

### Week 5-6: データ表示機能
- [ ] 履歴画面の実装
- [ ] カレンダービューの追加
- [ ] 基本的な統計情報の計算
- [ ] グラフ表示の実装

### Week 7-8: ゲーミフィケーション
- [ ] ポイントシステムの実装
- [ ] アチーブメント機能
- [ ] プロフィール画面
- [ ] シンプルなアニメーション追加

### Week 9-10: 品質向上
- [ ] バグ修正
- [ ] パフォーマンス最適化
- [ ] UIの改善
- [ ] テストの追加

### Week 11-12: リリース準備
- [ ] アプリアイコン・スプラッシュ画面
- [ ] ストア用スクリーンショット
- [ ] プライバシーポリシー作成
- [ ] リリースビルドの作成

## 3. 技術的な実装詳細

### 3.1 状態管理
```dart
// Providerを使用した例
class SleepProvider extends ChangeNotifier {
  bool _isTracking = false;
  DateTime? _sleepStartTime;
  List<SleepRecord> _records = [];
  
  void startTracking() {
    _isTracking = true;
    _sleepStartTime = DateTime.now();
    notifyListeners();
  }
  
  void stopTracking() {
    if (_isTracking && _sleepStartTime != null) {
      final record = SleepRecord(
        startTime: _sleepStartTime!,
        endTime: DateTime.now(),
      );
      _records.add(record);
      _isTracking = false;
      _sleepStartTime = null;
      notifyListeners();
    }
  }
}
```

### 3.2 データベース設計
```sql
-- 睡眠記録テーブル
CREATE TABLE sleep_records (
  id TEXT PRIMARY KEY,
  start_time INTEGER NOT NULL,
  end_time INTEGER NOT NULL,
  duration INTEGER NOT NULL,
  quality REAL,
  created_at INTEGER NOT NULL
);

-- ユーザー設定テーブル
CREATE TABLE user_settings (
  id INTEGER PRIMARY KEY,
  target_sleep_hours REAL,
  target_bedtime TEXT,
  target_wake_time TEXT,
  points INTEGER DEFAULT 0
);

-- アチーブメントテーブル
CREATE TABLE achievements (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  unlocked_at INTEGER,
  points INTEGER DEFAULT 0
);
```

### 3.3 バックグラウンド処理
- iOS: `BackgroundFetch`を使用
- Android: `WorkManager`を使用
- 省電力を考慮した実装

## 4. パッケージ選定

### 必須パッケージ
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状態管理
  provider: ^6.0.0
  
  # ローカルDB
  sqflite: ^2.2.0
  path: ^1.8.0
  
  # UI/UX
  fl_chart: ^0.63.0
  table_calendar: ^3.0.0
  
  # ユーティリティ
  intl: ^0.18.0
  uuid: ^3.0.0
  
  # 通知
  flutter_local_notifications: ^15.0.0
  
  # センサー（Phase 4で追加）
  # sensors_plus: ^3.0.0
  
  # バックグラウンド処理
  workmanager: ^0.5.0
```

### 開発用パッケージ
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

## 5. テスト戦略

### 5.1 単体テスト
- モデルクラスのテスト
- ビジネスロジックのテスト
- Repository層のテスト

### 5.2 ウィジェットテスト
- 各画面のUIテスト
- ユーザーインタラクションのテスト

### 5.3 統合テスト
- 睡眠記録の一連のフロー
- データの保存・読み込み

## 6. リリース計画

### 6.1 ベータ版リリース
- TestFlightでのiOSベータ配信
- Google Play Consoleでの内部テスト

### 6.2 正式リリース
- 段階的ロールアウト
- ユーザーフィードバックの収集
- 継続的な改善

## 7. 将来の拡張計画

### Version 2.0
- Apple HealthKit連携
- Google Fit連携
- ウィジェット対応

### Version 3.0
- ウェアラブルデバイス対応
- AI睡眠アドバイス機能
- ソーシャル機能

## 8. リスク管理

### 技術的リスク
- バッテリー消費の最適化
- バックグラウンド処理の制限
- プラットフォーム固有の問題

### 対策
- 早期のプロトタイプ作成
- 実機での継続的なテスト
- ユーザーフィードバックの活用