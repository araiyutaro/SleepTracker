# アプリ実行方法

## 基本的な実行方法

### 1. 通常の実行（Dev環境がデフォルト）
```bash
flutter run
```

### 2. Flavorを指定した実行（推奨）

#### Dev環境
```bash
flutter run --flavor dev --target lib/main_dev.dart
```

#### Prod環境
```bash
flutter run --flavor prod --target lib/main_prod.dart
```

### 3. スクリプトを使用した実行
```bash
# Dev環境
./scripts/run_dev.sh

# Prod環境
./scripts/run_prod.sh
```

## VS Codeでの実行

1. F5キーまたは「実行とデバッグ」パネルを開く
2. 上部のドロップダウンから環境を選択：
   - `sleep - Dev`: 開発環境
   - `sleep - Prod`: 本番環境

## Android Studioでの実行

1. 上部のRun Configurationドロップダウンを開く
2. 「Edit Configurations...」を選択
3. 「+」ボタンから「Flutter」を選択
4. 以下の設定を作成：

### Dev環境設定
- Name: `Sleep Dev`
- Dart entrypoint: `lib/main_dev.dart`
- Additional run args: `--flavor dev`

### Prod環境設定
- Name: `Sleep Prod`
- Dart entrypoint: `lib/main_prod.dart`
- Additional run args: `--flavor prod`

## トラブルシューティング

### FlavorConfigエラーが出る場合
通常の`flutter run`でFlavorConfigエラーが出る場合は、必ずflavorを指定して実行してください：
```bash
flutter run --flavor dev --target lib/main_dev.dart
```

### ホットリロードが効かない場合
Flavorを変更した場合は、ホットリスタート（Shift+R）またはフルリスタートが必要です。