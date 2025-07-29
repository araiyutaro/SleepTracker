# Build Flavors設定ガイド

## 概要
このアプリはdev（開発）とprod（本番）の2つの環境をサポートしています。

## セットアップ

### 1. Firebaseプロジェクトの設定

#### Android
- **Dev環境**: `android/app/src/dev/google-services.json`
- **Prod環境**: `android/app/src/prod/google-services.json`

#### iOS
- **Dev環境**: `ios/Runner/Firebase/Dev/GoogleService-Info.plist`
- **Prod環境**: `ios/Runner/Firebase/Prod/GoogleService-Info.plist`

### 2. バンドルID/パッケージ名

- **Dev環境**: `com.arai.sleep.dev`
- **Prod環境**: `com.arai.sleep`

## 実行方法

### コマンドラインから

```bash
# Dev環境で実行
flutter run --flavor dev --target lib/main_dev.dart

# Prod環境で実行
flutter run --flavor prod --target lib/main_prod.dart

# またはスクリプトを使用
./scripts/run_dev.sh
./scripts/run_prod.sh
```

### VS Codeから

1. F5キーまたは「実行とデバッグ」パネルを開く
2. 以下の設定から選択：
   - `sleep - Dev`: 開発環境（デバッグモード）
   - `sleep - Prod`: 本番環境（デバッグモード）
   - `sleep - Dev (release)`: 開発環境（リリースモード）
   - `sleep - Prod (release)`: 本番環境（リリースモード）

## ビルド方法

### Android APK

```bash
# Dev環境
flutter build apk --flavor dev --target lib/main_dev.dart

# Prod環境
flutter build apk --flavor prod --target lib/main_prod.dart
```

### iOS

```bash
# Dev環境
flutter build ios --flavor dev --target lib/main_dev.dart

# Prod環境
flutter build ios --flavor prod --target lib/main_prod.dart
```

## 環境別の違い

### Dev環境のみの機能
- ダミーデータ生成機能
- デバッグログの詳細出力
- アプリ名に「Dev」サフィックス表示

### Prod環境
- 本番用Firebase設定
- パフォーマンス最適化
- 余計なログ出力なし

## トラブルシューティング

### Androidビルドエラー
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
```

### iOSビルドエラー
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
```

### Firebaseエラー
- 各環境用の設定ファイルが正しい場所に配置されているか確認
- Bundle ID/Package Nameが正しいか確認
- Firebase ConsoleでアプリのBundle ID/Package Nameが登録されているか確認