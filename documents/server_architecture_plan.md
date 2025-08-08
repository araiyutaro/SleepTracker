# 睡眠分析システム サーバーアーキテクチャ計画

## 概要
睡眠トラッキングアプリのサーバーサイド実装において、AWS/Google Cloudで最もコスト効率的な構成を設計します。

## 推奨構成：サーバーレスアーキテクチャ

### なぜサーバーレスか？
- **使用時のみ課金**: 睡眠データは主に朝夕にアップロードされるため、常時稼働は不要
- **自動スケーリング**: ユーザー増加に自動対応
- **運用負荷最小**: サーバー管理不要
- **初期費用ゼロ**: 小規模から開始可能

## AWS構成（推奨）

### アーキテクチャ図
```
モバイルアプリ
    ↓
API Gateway ($3.5/100万リクエスト)
    ↓
Lambda Functions (月100万リクエスト無料枠)
    ├─ データ収集API
    ├─ 個人分析API
    └─ グループ分析API
    ↓
DynamoDB (月25GB無料枠)
    ├─ 睡眠記録テーブル
    ├─ 集計データテーブル
    └─ ユーザープロファイル
    ↓
S3 (月5GB無料枠)
    └─ バックアップ・アーカイブ
```

### 月額コスト見積もり（1000ユーザー想定）
```
API Gateway: $0.5 (15万リクエスト)
Lambda: $0 (無料枠内)
DynamoDB: $0 (無料枠内)
S3: $0 (無料枠内)
データ転送: $1-2

合計: 月額 $2-3 (約300-450円)
```

### 実装コード例

#### Lambda関数（データ収集）
```python
import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('sleep_records')

def lambda_handler(event, context):
    # リクエストボディを解析
    body = json.loads(event['body'])
    user_id = body['userId']
    sleep_data = body['sleepData']
    
    # データを匿名化
    anonymized_data = anonymize_sleep_data(sleep_data)
    
    # DynamoDBに保存
    table.put_item(
        Item={
            'userId': user_id,
            'timestamp': datetime.now().isoformat(),
            'sleepDuration': anonymized_data['duration'],
            'quality': anonymized_data['quality'],
            'ageGroup': anonymized_data['ageGroup'],
            'occupation': anonymized_data['occupation']
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Data saved successfully'})
    }

def anonymize_sleep_data(data):
    # 個人識別情報を除去
    return {
        'duration': data['duration'],
        'quality': data['quality'],
        'ageGroup': data['userProfile']['ageGroup'],
        'occupation': data['userProfile']['occupation']
    }
```

#### Lambda関数（グループ分析）
```python
import boto3
from boto3.dynamodb.conditions import Key

def get_group_statistics(event, context):
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table('sleep_aggregates')
    
    # クエリパラメータ取得
    age_group = event['queryStringParameters']['ageGroup']
    
    # 集計データを取得
    response = table.query(
        KeyConditionExpression=Key('ageGroup').eq(age_group)
    )
    
    # 統計計算
    items = response['Items']
    avg_duration = sum(item['avgDuration'] for item in items) / len(items)
    avg_quality = sum(item['avgQuality'] for item in items) / len(items)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'ageGroup': age_group,
            'averageDuration': avg_duration,
            'averageQuality': avg_quality,
            'sampleSize': len(items)
        })
    }
```

## Google Cloud構成（代替案）

### アーキテクチャ
```
モバイルアプリ
    ↓
Cloud Endpoints
    ↓
Cloud Functions (月200万呼び出し無料)
    ↓
Firestore (月1GB無料枠)
    ↓
Cloud Storage (月5GB無料枠)
```

### 月額コスト見積もり（1000ユーザー想定）
```
Cloud Functions: $0 (無料枠内)
Firestore: $0-2 (読み取り/書き込み回数による)
Cloud Storage: $0 (無料枠内)

合計: 月額 $0-3 (約0-450円)
```

## スケーリング戦略

### フェーズ1（〜1万ユーザー）
- 基本構成のまま運用
- 月額 $10以下

### フェーズ2（1万〜10万ユーザー）
- DynamoDBのオンデマンド課金
- CloudFrontでキャッシュ最適化
- 月額 $50-100

### フェーズ3（10万ユーザー〜）
- 予約キャパシティで割引
- データレイク構築（S3 + Athena）
- 月額 $500〜

## セキュリティ設計

### API認証
```javascript
// Flutterアプリ側
class ApiClient {
  final String apiKey;
  final String baseUrl = 'https://api.sleeptracker.com';
  
  Future<void> uploadSleepData(SleepData data) async {
    final token = await getIdToken(); // Firebase Auth等
    
    final response = await http.post(
      Uri.parse('$baseUrl/sleep-records'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-API-Key': apiKey,
      },
      body: jsonEncode(data.toJson()),
    );
  }
}
```

### データ暗号化
- 転送時: HTTPS必須
- 保存時: DynamoDB/Firestoreの暗号化機能
- バックアップ: S3のサーバーサイド暗号化

## 実装ロードマップ

### 第1週：基盤構築
1. AWSアカウント設定
2. API Gateway + Lambda基本構成
3. DynamoDBテーブル作成
4. 認証システム実装

### 第2週：データ収集API
1. 睡眠データアップロードAPI
2. データ検証・匿名化処理
3. エラーハンドリング
4. Flutter側の統合

### 第3週：分析API
1. 個人統計API
2. グループ比較API
3. キャッシュ戦略実装
4. レート制限設定

### 第4週：運用準備
1. CloudWatchモニタリング
2. アラート設定
3. バックアップ自動化
4. ドキュメント整備

## コスト最適化のポイント

1. **無料枠の活用**
   - AWS/GCPの永続無料枠を最大限利用
   - 新規アカウントの12ヶ月無料枠も活用

2. **効率的なデータ設計**
   - 必要最小限のデータのみ保存
   - 古いデータはS3にアーカイブ

3. **キャッシュ戦略**
   - 統計データは事前計算してキャッシュ
   - CloudFront/Cloud CDNで配信最適化

4. **バッチ処理**
   - リアルタイム不要な処理は夜間バッチに
   - Lambda の予約同時実行数で制御

## モニタリング設計

### CloudWatch/Cloud Monitoring設定
```yaml
アラート設定:
  - APIエラー率 > 5%
  - Lambda実行時間 > 3秒
  - DynamoDB読み取りキャパシティ > 80%
  - 月額請求 > $10

ダッシュボード:
  - API呼び出し回数
  - 平均レスポンス時間
  - エラー率
  - アクティブユーザー数
```

## まとめ

### 推奨構成の利点
- **超低コスト**: 月額300円程度から開始可能
- **高可用性**: AWSのマネージドサービスで99.9%稼働
- **開発効率**: サーバー管理不要でアプリ開発に集中
- **段階的拡張**: ユーザー増加に応じて構成変更可能

### 次のステップ
1. AWSアカウントの作成
2. 基本的なLambda関数の実装
3. Flutterアプリとの接続テスト
4. 段階的な機能追加