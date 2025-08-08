# 未実装機能一覧

## 🔴 重要度：高（コア機能に影響）

### 1. Firebase認証とクラウド同期
**ファイル**: `lib/services/firebase_service.dart`
- **現状**: iOS互換性のため一時的に無効化
- **影響**: 
  - ユーザー認証機能なし
  - クラウドバックアップ/同期なし
  - 複数デバイス間でのデータ共有不可
- **必要な作業**:
  - Firebase Auth統合の再実装
  - iOS/Android両対応の確認

### 2. プッシュ通知（iOS）
**ファイル**: `lib/services/push_notification_service.dart`
- **現状**: 無料のApple Developer Accountでは動作不可
- **影響**: iOSでリマインダー通知が送れない
- **必要な作業**:
  - Apple Developer Program（$99/年）への加入
  - APNs証明書の設定

### 3. 本番環境設定
**ファイル**: `android/app/build.gradle`
- **現状**: 
  - Application IDが仮のまま（TODO: line 46）
  - リリース署名設定が未完了（TODO: line 72）
- **必要な作業**:
  - 本番用のApplication ID設定
  - keystoreファイルの作成と設定

## 🟡 重要度：中（機能拡張）

### 4. ユーザープロフィール管理
**ファイル**: `lib/services/personal_analytics_service.dart:391`
- **現状**: ダミーデータを返却（TODO）
- **影響**: パーソナライズされた分析が不可
- **必要な作業**:
  - 実際のユーザープロフィール取得実装
  - プロフィール編集機能の追加

### 5. Health Connect/HealthKit統合
**ファイル**: `lib/services/health_service.dart:288`
- **現状**: 空のデータ構造を返却
- **影響**: デバイスのヘルスデータと連携できない
- **必要な作業**:
  - 実際のヘルスデータ取得実装
  - 権限リクエストフローの改善

### 6. Firebase Cloud Functions連携
**ファイル**: `lib/services/firebase_service.dart`
- **現状**: エンドポイント定義済みだが認証なしでは動作不可
- **影響**:
  - グループ分析機能なし
  - トレンド分析機能なし
  - 研究データ収集なし

## 🟢 重要度：低（改善項目）

### 7. 高度な睡眠分析
**ファイル**: `lib/services/sensor_service.dart`
- **現状**: 基本的な動き検出のみ
- **改善案**:
  - 機械学習による睡眠段階予測
  - より正確な睡眠サイクル分析

### 8. データインポート機能
**ファイル**: `lib/services/export_service.dart`
- **現状**: エクスポートのみ実装
- **改善案**:
  - CSVインポート機能
  - 他アプリからのデータ移行

### 9. 研究データ収集
- **現状**: UIのみ存在、バックエンドなし
- **改善案**:
  - 匿名データ収集の実装
  - 研究機関向けAPI

## 📋 実装優先順位の推奨

1. **本番環境設定**（リリースに必須）
2. **Firebase認証**（データ永続化に必須）
3. **Health Connect統合**（競合優位性）
4. **プッシュ通知**（ユーザーエンゲージメント）
5. その他の機能改善

## 🛠️ 開発時の注意事項

- Firebase機能を有効化する際は、iOS/Android両方でのテストが必要
- プッシュ通知はAndroidで先行実装し、iOS は有料アカウント取得後に対応
- ヘルスデータ連携は各プラットフォームのガイドラインに準拠