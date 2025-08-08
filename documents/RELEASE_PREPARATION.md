# 本番リリース準備ドキュメント

## 1. アプリケーション識別子の設定

### Android Application ID
- 開発環境: `com.yourdomain.sleeptracker.dev`
- 本番環境: `com.yourdomain.sleeptracker`

### iOS Bundle ID
- 開発環境: `com.yourdomain.sleeptracker.dev`
- 本番環境: `com.yourdomain.sleeptracker`

**注意**: `yourdomain`を実際のドメイン名に置き換えてください。
例: `com.example.sleeptracker`

## 2. アプリ名
- 開発版: "Sleep Tracker Dev"
- 本番版: "Sleep Tracker"

## 3. 必要な変更箇所

### Android
1. `android/app/build.gradle`のapplicationIdを変更
2. `android/app/src/main/kotlin/com/arai/sleep/MainActivity.kt`のパッケージ名を変更
3. ディレクトリ構造を新しいパッケージ名に合わせて変更

### iOS
1. XcodeでBundle IDを変更
2. `ios/Runner/Info.plist`のCFBundleIdentifierを確認

## 4. Firebase設定
新しいApplication ID/Bundle IDに合わせて：
1. Firebase Consoleで新しいアプリを登録
2. `google-services.json`（Android）を更新
3. `GoogleService-Info.plist`（iOS）を更新
4. `flutterfire configure`を再実行

## 5. 署名設定

### Android
```bash
# keystoreファイルの生成
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### iOS
1. Apple Developer Programでアプリを登録
2. 証明書とプロビジョニングプロファイルを作成
3. Xcodeで設定

## 6. アプリアイコン
- `assets/icon/icon.png`を最終版に更新
- `flutter pub run flutter_launcher_icons:main`を実行