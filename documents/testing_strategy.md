# テスト戦略とユニットテスト仕様書

## テスト概要

睡眠記録アプリのテスト戦略とユニットテストの実装について説明します。

## テスト構造

### テストディレクトリ構造
```
test/
├── domain/
│   ├── entities/
│   │   ├── sleep_session_test.dart
│   │   └── user_profile_test.dart
│   └── usecases/
│       ├── start_sleep_tracking_usecase_test.dart
│       └── end_sleep_tracking_usecase_test.dart
├── presentation/
│   └── providers/
│       └── user_provider_test.dart
├── services/
│   └── sensor_service_test.dart
└── widget_test.dart
```

## テスト種別

### 1. エンティティテスト（Entities）

#### SleepSession テスト
- **目的**: 睡眠セッションエンティティの基本機能をテスト
- **テストケース**:
  - 有効な睡眠セッションの作成
  - 終了時刻なしでの睡眠セッション作成
  - copyWithメソッドによる更新
  - MovementDataの作成
  - SleepStageDataの作成

#### UserProfile テスト
- **目的**: ユーザープロフィールエンティティの機能をテスト
- **テストケース**:
  - 有効なユーザープロフィールの作成
  - copyWithメソッドによる設定更新
  - Achievementの作成と状態管理
  - NotificationSettingsのデフォルト値とカスタム設定

### 2. ユースケーステスト（Use Cases）

#### StartSleepTrackingUseCase テスト
- **目的**: 睡眠記録開始の業務ロジックをテスト
- **テストケース**:
  - 正常な睡眠記録開始
  - アクティブセッション存在時の例外処理
  - データベースエラー時の例外処理

#### EndSleepTrackingUseCase テスト
- **目的**: 睡眠記録終了とポイント計算をテスト
- **テストケース**:
  - 正常な睡眠記録終了とポイント付与
  - 高品質睡眠時のボーナスポイント
  - アクティブセッション不在時の例外処理
  - データベースエラー時の例外処理

### 3. サービステスト（Services）

#### SensorService テスト
- **目的**: センサー分析ロジックをテスト
- **テストケース**:
  - 低動作時の高品質睡眠分析
  - 高動作時の低品質睡眠分析
  - 空の動作データの処理
  - 期間指定での動作データ取得
  - 睡眠ステージ比率の合計検証

### 4. プロバイダーテスト（Providers）

#### UserProvider テスト
- **目的**: ユーザー状態管理とビジネスロジックをテスト
- **テストケース**:
  - 初期化時のユーザープロフィール読み込み
  - 設定更新の正常処理
  - 通知設定の更新
  - ポイント追加処理
  - アチーブメント解除処理
  - nullプロフィールの適切な処理

## テストツールと設定

### 使用ツール
- **flutter_test**: Flutterの公式テストフレームワーク
- **mockito**: モックオブジェクト生成
- **build_runner**: モックファイル自動生成

### 依存関係
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.3.2
  build_runner: ^2.3.3
```

### モック生成
```bash
dart run build_runner build
```

## テスト実行

### 全テスト実行
```bash
flutter test
```

### 特定カテゴリのテスト実行
```bash
flutter test test/domain/
flutter test test/services/
flutter test test/presentation/
```

### 個別テストファイル実行
```bash
flutter test test/domain/entities/sleep_session_test.dart
```

## テストカバレッジ目標

### カバレッジ目標
- **Domain Layer**: 95%以上
- **Use Cases**: 90%以上
- **Services**: 85%以上
- **Providers**: 80%以上

### カバレッジ重点項目
1. **ビジネスロジック**: 完全カバー必須
2. **エラーハンドリング**: 例外ケース網羅
3. **データ変換**: 境界値テスト実施
4. **状態遷移**: 全状態パターンテスト

## モック戦略

### モック対象
- **Repository**: データアクセス層の抽象化
- **Service**: 外部サービス（通知、センサー）
- **Provider**: 他のプロバイダーとの依存関係

### モック指針
1. **インターフェース優先**: 実装ではなくインターフェースをモック
2. **最小限のモック**: 必要最小限の範囲でモック使用
3. **実装に近い動作**: 実際の動作に近いモック設定

## テストデータ管理

### テストデータ原則
1. **決定論的**: 毎回同じ結果を保証
2. **独立性**: テスト間でデータ共有しない
3. **最小限**: テストに必要最小限のデータ
4. **可読性**: テストの意図が明確

### サンプルデータ例
```dart
// 標準的な睡眠セッション
final testSleepSession = SleepSession(
  id: 'test-session-id',
  startTime: DateTime(2025, 7, 6, 22, 0),
  endTime: DateTime(2025, 7, 7, 6, 0),
  duration: Duration(hours: 8),
  qualityScore: 85.0,
  movements: [],
  createdAt: DateTime(2025, 7, 6, 22, 0),
);
```

## 継続的インテグレーション

### CI/CDでのテスト実行
```yaml
# GitHub Actions例
- name: Run tests
  run: flutter test --coverage
  
- name: Check coverage
  run: |
    lcov --summary coverage/lcov.info
    genhtml coverage/lcov.info -o coverage/html
```

### テスト品質チェック
1. **カバレッジ閾値**: 最低80%を維持
2. **テスト実行時間**: 全テスト5分以内
3. **フレイキーテスト**: 不安定なテストの排除

## テスト保守

### リファクタリング指針
1. **DRY原則**: 重複コードの排除
2. **可読性重視**: テストの意図を明確に
3. **メンテナンス性**: 仕様変更に強いテスト設計

### テスト追加のタイミング
1. **新機能追加時**: 機能実装と同時にテスト作成
2. **バグ修正時**: 再発防止のためのテスト追加
3. **リファクタリング時**: 動作保証のためのテスト強化

## パフォーマンステスト

### 対象項目
1. **データベース操作**: 大量データでの性能検証
2. **センサー分析**: 長時間データの処理性能
3. **UI応答性**: 状態更新の応答時間

### 性能目標
- **データベースクエリ**: 100ms以内
- **センサー分析**: 1000件/秒以上
- **UI更新**: 60fps維持

## まとめ

このテスト戦略により、以下を実現します：

1. **品質保証**: バグの早期発見と修正
2. **リファクタリング安全性**: 安心してコード改善
3. **ドキュメント化**: テストがコードの仕様書として機能
4. **開発効率**: 自動テストによる手動テスト削減

継続的にテストを改善し、高品質なアプリケーションの維持に努めます。