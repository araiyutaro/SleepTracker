# Firebase設定手順

## ⚠️ 重要なセキュリティ注意事項

**絶対に** `google-services.json` や `GoogleService-Info.plist` をGitにコミットしないでください。これらのファイルには機密のAPIキーが含まれています。

## セットアップ手順

### 1. Firebase Consoleでプロジェクトを作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 新しいプロジェクトを作成するか、既存のプロジェクトを選択
3. Analytics を有効にする

### 2. Android アプリを追加

1. Firebase Console で「Android アプリを追加」をクリック
2. パッケージ名: `com.arai.sleep`
3. アプリのニックネーム: `Sleep Tracker`
4. `google-services.json` をダウンロード
5. **重要**: `google-services.json` を `android/app/` ディレクトリに配置

### 3. iOS アプリを追加

1. Firebase Console で「iOS アプリを追加」をクリック
2. Bundle ID: `com.arai.sleep`
3. アプリのニックネーム: `Sleep Tracker`
4. `GoogleService-Info.plist` をダウンロード
5. **重要**: `GoogleService-Info.plist` を `ios/Runner/` ディレクトリに配置

### 4. firebase_options.dart の更新

1. Firebase CLI をインストール: `npm install -g firebase-tools`
2. ログイン: `firebase login`
3. FlutterFire CLI をインストール: `dart pub global activate flutterfire_cli`
4. 設定を生成: `flutterfire configure`

### 5. 設定ファイルの確認

以下のファイルが正しく配置されていることを確認してください:

```
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

### 6. .gitignore の確認

`.gitignore` に以下が含まれていることを確認してください:

```
# Firebase config files (NEVER COMMIT THESE)
google-services.json
android/app/google-services.json
GoogleService-Info.plist
ios/Runner/GoogleService-Info.plist
```

## テンプレートファイル

テンプレートファイルが用意されています:

- `android/app/google-services.json.template`
- `ios/Runner/GoogleService-Info.plist.template`

これらをコピーして実際の値に置き換えてください。

## トラブルシューティング

### Firebase初期化エラー

エラーが発生する場合は、以下を確認してください:

1. 設定ファイルが正しい場所に配置されているか
2. Bundle ID / Package Name が一致しているか
3. Firebase プロジェクトでアプリが正しく登録されているか

### ビルドエラー

- iOS: Xcode でプロジェクトをクリーンしてリビルド
- Android: `flutter clean && flutter pub get` を実行

## セキュリティベストプラクティス

1. **設定ファイルを共有しない**: Firebase設定ファイルは機密情報です
2. **環境別設定**: 開発・本番で異なるFirebaseプロジェクトを使用する
3. **アクセス制御**: Firebase Console でアクセス権限を適切に設定する
4. **定期的な監査**: 不要なAPIキーやプロジェクトを削除する