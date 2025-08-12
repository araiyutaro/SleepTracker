# ビルドコマンド一覧

## Android

### 開発版（デバッグ機能あり）
```bash
# APK
flutter build apk --release --flavor dev -t lib/main_dev.dart

# App Bundle
flutter build appbundle --release --flavor dev -t lib/main_dev.dart
```

### 本番版（デバッグ機能なし）
```bash
# APK
flutter build apk --release --flavor prod -t lib/main_prod.dart

# App Bundle（Google Play用）
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```

## iOS

### 開発版
```bash
flutter build ios --release --flavor dev -t lib/main_dev.dart
```

### 本番版
```bash
flutter build ios --release --flavor prod -t lib/main_prod.dart
```

## 実行コマンド（開発時）

### 開発版で実行
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### 本番版で実行
```bash
flutter run --flavor prod -t lib/main_prod.dart
```

## 注意事項

1. **エントリーポイントの指定が必須**: `-t lib/main_xxx.dart`を必ず指定してください
2. **Flavorの指定が必須**: `--flavor dev`または`--flavor prod`を必ず指定してください
3. **本番版では以下の機能が無効化されます**:
   - ダミーユーザー作成ボタン（オンボーディング画面）
   - デモデータ追加機能（プロフィール画面）

## トラブルシューティング

### 機能が正しく制限されない場合
1. ビルドキャッシュをクリア: `flutter clean`
2. 正しいエントリーポイントを指定しているか確認
3. Flavorが正しく指定されているか確認