# データベース選定ガイド

## 推奨：Cloud Firestore

### 選定理由

1. **睡眠データの特性に最適**
   - 時系列データの効率的な保存
   - 日付範囲でのクエリが容易
   - ユーザーごとのデータ分離が簡単

2. **オフライン対応**
   - 自動的にローカルキャッシュ
   - ネットワーク復帰時に自動同期
   - 睡眠記録アプリには必須機能

3. **スケーラビリティ**
   - ユーザー数増加に自動対応
   - 読み書き性能が安定

## Firestoreデータ設計

```javascript
// ユーザードキュメント
users/{userId} {
  email: string,
  name: string,
  createdAt: timestamp,
  settings: {
    notificationEnabled: boolean,
    bedtimeReminder: string
  }
}

// 睡眠セッション（サブコレクション）
users/{userId}/sleepSessions/{sessionId} {
  startTime: timestamp,
  endTime: timestamp,
  duration: number,
  quality: number,
  notes: string,
  stages: [{
    stage: string,
    startTime: timestamp,
    duration: number
  }]
}

// テスト結果（サブコレクション）
users/{userId}/testResults/{testId} {
  testType: string,
  completedAt: timestamp,
  score: number,
  answers: [{
    questionId: string,
    answer: any
  }]
}

// 集計データ（別コレクション）
dailyAggregates/{userId}_{date} {
  userId: string,
  date: string,
  totalSleep: number,
  avgQuality: number,
  sessionsCount: number
}
```

## セキュリティルール例

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /{subcollection}/{document} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // 集計データは読み取りのみ
    match /dailyAggregates/{aggregateId} {
      allow read: if request.auth != null 
        && resource.data.userId == request.auth.uid;
      allow write: if false; // Cloud Functionsからのみ書き込み
    }
  }
}
```

## 実装の優先順位

### Phase 1: 基本実装
1. Firebase Authentication有効化
2. Firestore基本CRUD実装
3. オフライン対応確認

### Phase 2: 最適化
1. 複合インデックス設定
2. データ集計用Cloud Functions
3. セキュリティルール強化

### Phase 3: 分析基盤
1. BigQueryエクスポート設定
2. データ分析パイプライン構築
3. 機械学習モデル開発

## コスト試算（月額）

### 1,000ユーザーの場合
- Firestore読み取り: 3M回 × $0.06/100K = $1.80
- Firestore書き込み: 300K回 × $0.18/100K = $0.54
- ストレージ: 10GB × $0.18 = $1.80
- **合計: 約$4.14/月**

### 10,000ユーザーの場合
- Firestore読み取り: 30M回 × $0.06/100K = $18
- Firestore書き込み: 3M回 × $0.18/100K = $5.40
- ストレージ: 100GB × $0.18 = $18
- **合計: 約$41.40/月**

## 移行時の注意点

現在のSQLiteデータからFirestoreへの移行：
1. エクスポート機能でJSONエクスポート
2. Cloud Functionsでバッチインポート
3. 段階的移行（新規データから）
4. 既存ユーザーへの影響最小化