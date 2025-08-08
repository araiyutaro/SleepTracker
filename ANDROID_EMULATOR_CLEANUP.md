# Android エミュレーター容量不足の解決方法

## 問題の症状
```
adb: failed to install: Failure [INSTALL_FAILED_INSUFFICIENT_STORAGE]
```

## 解決方法

### 1. 容量の確認
```bash
# エミュレーターの容量確認
adb -s <emulator-id> shell df -h

# 例: emulator-5554の場合
adb -s emulator-5554 shell df -h
```

### 2. 別のエミュレーターの使用（推奨）
```bash
# 利用可能なエミュレーターを確認
flutter devices

# 容量の多いエミュレーターでアプリを実行
flutter run --device-id emulator-5556 --flavor dev --target lib/main_dev.dart
```

### 3. エミュレーターの容量クリーンアップ

#### 不要なアプリを削除
```bash
# インストール済みパッケージ一覧
adb -s emulator-5554 shell pm list packages

# 不要なアプリを削除（例）
adb -s emulator-5554 shell pm uninstall com.expressvpn.vpn
adb -s emulator-5554 shell pm uninstall com.dena.mj
```

#### キャッシュクリア
```bash
# 全アプリのキャッシュクリア
adb -s emulator-5554 shell pm trim-caches 1000000000

# システムキャッシュクリア
adb -s emulator-5554 shell rm -rf /data/dalvik-cache/*
```

### 4. 新しいエミュレーターの作成（最終手段）
```bash
# 利用可能なエミュレーターを表示
flutter emulators

# 新しいエミュレーターを作成
flutter emulators --create --name pixel_7_api_34

# 作成したエミュレーターで起動
flutter emulators --launch pixel_7_api_34
```

## 予防策

### エミュレーター作成時により大きなストレージを設定
1. Android Studioを開く
2. AVD Manager → Create Virtual Device
3. Show Advanced Settings
4. Internal Storage を 8GB以上に設定
5. SD Card を追加（4GB推奨）

### 定期的なクリーンアップ
```bash
# 開発用アプリの削除
adb shell pm uninstall com.arai.sleep.dev

# Gradleキャッシュクリア
./gradlew clean
flutter clean
```