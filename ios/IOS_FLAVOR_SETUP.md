# iOS Flavor設定手順

## 自動設定（推奨）

1. ターミナルで以下を実行：
```bash
cd ios
./create_schemes.sh
```

## Xcodeでの手動設定

### 1. Build Configurationsの追加

1. Xcodeでプロジェクトを開く
2. プロジェクトナビゲーターで「Runner」プロジェクトを選択
3. 「Runner」プロジェクト（青いアイコン）を選択
4. 「Info」タブを選択
5. 「Configurations」セクションで以下を追加：
   - 「Debug」を複製して「Debug-Dev」を作成
   - 「Debug」を複製して「Debug-Prod」を作成
   - 「Release」を複製して「Release-Dev」を作成
   - 「Release」を複製して「Release-Prod」を作成

### 2. Build Phasesの確認

1. 「Runner」ターゲットを選択
2. 「Build Phases」タブを選択
3. 「Copy Firebase Config」というスクリプトフェーズが存在することを確認
   - 存在しない場合は「+」ボタンから「New Run Script Phase」を追加
   - 名前を「Copy Firebase Config」に変更
   - スクリプト欄に以下を入力：
   ```bash
   "${SRCROOT}/Runner/copy-firebase-config.sh"
   ```

### 3. Schemeの設定

1. Xcode上部のScheme選択メニューから「Manage Schemes...」を選択
2. 既存の「Runner」スキームを複製
3. 「Runner-Dev」と「Runner-Prod」を作成
4. 各Schemeで以下を設定：

#### Runner-Dev:
- Run: Debug-Dev
- Test: Debug-Dev
- Profile: Release-Dev
- Analyze: Debug-Dev
- Archive: Release-Dev

#### Runner-Prod:
- Run: Debug-Prod
- Test: Debug-Prod
- Profile: Release-Prod
- Analyze: Debug-Prod
- Archive: Release-Prod

## copy-firebase-config.shスクリプトの動作

このスクリプトは以下の条件でFirebase設定ファイルをコピーします：

1. Configuration名に「Dev」が含まれる → `Firebase/Dev/GoogleService-Info.plist`をコピー
2. Configuration名に「Prod」が含まれる → `Firebase/Prod/GoogleService-Info.plist`をコピー
3. それ以外でDebugビルド → Dev設定を使用
4. それ以外でReleaseビルド → Prod設定を使用

## トラブルシューティング

### スクリプトが実行されない場合

1. スクリプトファイルの実行権限を確認：
```bash
chmod +x ios/Runner/copy-firebase-config.sh
```

2. Build Phasesでスクリプトの順序を確認（「Compile Sources」より前に配置）

### Firebase設定ファイルが見つからないエラー

1. 以下のパスにファイルが存在することを確認：
   - `ios/Runner/Firebase/Dev/GoogleService-Info.plist`
   - `ios/Runner/Firebase/Prod/GoogleService-Info.plist`

### ビルドエラーが発生する場合

```bash
cd ios
pod deintegrate
pod install
```