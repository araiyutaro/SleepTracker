# Google Analytics ログ仕様書

## 概要

本アプリでは Firebase Analytics を使用してユーザーの行動やアプリの使用状況を分析しています。
収集されるデータは匿名化され、ユーザーのプライバシーを保護しています。

## ライブラリ

- パッケージ: `firebase_analytics: ^11.5.2`
- サービスクラス: `lib/services/analytics_service.dart`

## ユーザープロパティ

### setUserProperties メソッド

以下のユーザープロパティを設定できます：

| プロパティ名 | 型 | 説明 |
|-------------|----|----|
| userId | String | ユーザーID |
| age_group | String | 年齢グループ |
| gender | String | 性別 |
| occupation | String | 職業 |

## イベント一覧

### オンボーディング関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| onboarding_started | なし | オンボーディング開始 |
| onboarding_completed | age_group, gender, occupation | オンボーディング完了 |
| onboarding_step_completed | step_name | オンボーディングステップ完了 |

### 睡眠記録関連

#### 自動睡眠記録

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| sleep_record_started | timestamp, source | 睡眠記録開始 |
| sleep_record_completed | duration_minutes, duration_hours, quality_score, wake_quality, has_movement_data, has_sleep_stages, completion_timestamp | 睡眠記録完了 |

#### 手動睡眠記録

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| manual_sleep_record_added | duration_minutes, duration_hours, quality_score, wake_quality, source, timestamp | 手動睡眠記録追加 |

#### 睡眠記録編集・削除

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| sleep_record_edited | session_id (匿名化), duration_minutes, duration_hours, quality_score, wake_quality, edit_timestamp | 睡眠記録編集 |
| sleep_record_deleted | delete_timestamp | 睡眠記録削除 |

#### その他睡眠関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| wake_quality_rated | rating, timestamp | 起床時の睡眠品質評価 |
| sleep_data_exported | export_format, timestamp | 睡眠データエクスポート |

### データ管理関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| demo_data_generated | record_count, timestamp | デモデータ生成 |
| all_data_cleared | timestamp | 全データ削除 |
| backup_created | record_count, timestamp | バックアップ作成 |
| backup_restored | record_count, timestamp | バックアップ復元 |

### 設定関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| settings_changed | setting_name, setting_value | 設定変更 |
| notification_settings_changed | bedtime_reminder_enabled, wake_up_alarm_enabled | 通知設定変更 |

### UIインタラクション関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| button_tapped | button_name, timestamp, context (オプション) | ボタンタップ |
| navigation | from_screen, to_screen, timestamp | 画面遷移 |
| dialog_opened | dialog_name, timestamp | ダイアログ表示 |
| feature_used | feature_name, timestamp, metadata (オプション) | 機能使用 |

### アプリ使用状況関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| app_opened | timestamp | アプリ起動 |
| app_backgrounded | timestamp | アプリバックグラウンド移行 |
| app_foregrounded | timestamp | アプリフォアグラウンド復帰 |

### 画面表示

| メソッド名 | パラメータ | 説明 |
|-----------|----------|------|
| logScreenView | screenName | 画面表示ログ |

### エラー・例外関連

| イベント名 | パラメータ | 説明 |
|-----------|----------|------|
| app_error | error_name, error_message | アプリエラー |

### カスタムイベント

| メソッド名 | パラメータ | 説明 |
|-----------|----------|------|
| logCustomEvent | eventName, parameters (オプション) | カスタムイベント |

## パラメータ詳細

### 睡眠記録関連のパラメータ

| パラメータ名 | 型 | 説明 |
|-------------|----|----|
| duration_minutes | int | 睡眠時間（分） |
| duration_hours | int | 睡眠時間（時間・四捨五入） |
| quality_score | int | 睡眠品質スコア（四捨五入） |
| wake_quality | int | 起床時品質評価 |
| has_movement_data | bool | 動作データ有無 |
| has_sleep_stages | bool | 睡眠ステージデータ有無 |
| timestamp | int | タイムスタンプ（ミリ秒） |
| source | String | データソース（"automatic", "manual"） |

### UI関連のパラメータ

| パラメータ名 | 型 | 説明 |
|-------------|----|----|
| button_name | String | ボタン名 |
| from_screen | String | 遷移元画面 |
| to_screen | String | 遷移先画面 |
| dialog_name | String | ダイアログ名 |
| feature_name | String | 機能名 |

## プライバシー配慮

- session_id は最初の8文字のみを記録（匿名化）
- 個人を特定可能な情報は記録しない
- 数値データは適切に丸められる（quality_score等）
- すべてのログは初期化状態でのみ記録される

## 初期化とエラーハンドリング

- Analytics サービスが初期化されていない場合、ログは記録されずデバッグメッセージが出力される
- すべてのメソッドで例外処理が実装されている
- スタブモードでの動作も対応

## デバッグ情報

- `setAnalyticsCollectionEnabled(bool enabled)`: Analytics データ収集の有効/無効切り替え
- `logFirstOpen()`: アプリ初回起動イベント