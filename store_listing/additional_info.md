# Google Play Console 追加情報

## アプリの詳細

### アプリのアクセス権限
以下の権限を使用します：

#### 必須権限
- **android.permission.health.READ_SLEEP**: Google Health Connectから睡眠データを読み取る（将来の機能用）
- **android.permission.health.WRITE_SLEEP**: Google Health Connectに睡眠データを書き込む
- **android.permission.READ_EXTERNAL_STORAGE**: データのエクスポート用
- **android.permission.WRITE_EXTERNAL_STORAGE**: データのエクスポート用

### データの安全性
- **データ収集**: あり
- **データ共有**: なし
- **データの暗号化**: 転送時および保存時に暗号化
- **データの削除**: ユーザーはいつでもデータを削除可能

### 収集するデータの種類
- **個人情報**:
  - 年齢範囲（オプション）
  - 性別（オプション）
- **健康とフィットネス**:
  - 睡眠データ（就寝・起床時刻）
  - 睡眠の質の主観的評価
- **アプリのアクティビティ**:
  - アプリ内での操作（分析目的）

### ターゲット層
- **年齢層**: 全年齢
- **対象地域**: 全世界（初期リリースは日本）

### 収益化
- **広告**: なし
- **アプリ内購入**: なし（現時点）
- **有料アプリ**: いいえ

### サポート情報
- **サポートメール**: meganecatcher27@gmail.com
- **対応言語**: 日本語、英語（予定）
- **対応時間**: 平日 9:00-18:00 JST

### 技術仕様
- **最小Android SDK**: 26 (Android 8.0)
- **ターゲットAndroid SDK**: 34 (Android 14)
- **アーキテクチャ**: arm64-v8a, armeabi-v7a
- **使用ライブラリ**: Flutter, Firebase

### 法的情報
- **プライバシーポリシー**: https://araiyutaro.github.io/SleepTracker/privacy_policy.html
- **利用規約**: https://araiyutaro.github.io/SleepTracker/terms_of_service.html
- **開発者名**: 新井雄太郎
- **所在地**: 日本