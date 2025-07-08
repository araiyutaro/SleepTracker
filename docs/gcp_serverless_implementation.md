# Google Cloud サーバーレス分析機能実装計画

## 概要
Google Cloud Platform (GCP) を使用して、睡眠アプリの分析機能をサーバーレスで実装します。Cloud Functions + Firestore + Firebase Auth の構成で低コスト・高可用性を実現します。

## アーキテクチャ

```
Flutter App (Firebase SDK)
    ↓ (Firebase Auth)
Cloud Functions (Node.js/Python)
    ↓
Firestore (NoSQL Database)
    ↓
Cloud Storage (バックアップ・アーカイブ)
```

## 実装フェーズ

### フェーズ1: 基盤構築（1週間）

#### 1.1 Google Cloud プロジェクト設定
```bash
# Google Cloud CLI インストール・設定
gcloud auth login
gcloud projects create sleep-tracker-analytics
gcloud config set project sleep-tracker-analytics

# 必要なAPIを有効化
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable firebase.googleapis.com
```

#### 1.2 Firebase プロジェクト初期化
```bash
# Firebase CLI インストール
npm install -g firebase-tools

# プロジェクト初期化
firebase login
firebase init functions
firebase init firestore
firebase init auth
```

#### 1.3 Firestore データベース設計

**コレクション構造:**
```
users/{userId}
  - profile: ユーザープロファイル
  - sleepSessions/{sessionId}: 個別睡眠セッション
  - dailyAggregates/{date}: 日次集計データ
  - weeklyAggregates/{weekStart}: 週次集計データ

analytics/
  groupStats/{ageGroup-occupation}: グループ統計
  trends/{date}: 全体トレンド
```

### フェーズ2: データアップロードAPI（1週間）

#### 2.1 睡眠データアップロード関数
```javascript
// functions/src/uploadSleepData.js
const functions = require('firebase-functions');
const admin = require('firebase-admin');

exports.uploadSleepData = functions.https.onCall(async (data, context) => {
  // 認証チェック
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }

  const userId = context.auth.uid;
  const { sleepSession } = data;

  try {
    // Firestore トランザクション
    const db = admin.firestore();
    
    await db.runTransaction(async (transaction) => {
      // 1. 睡眠セッションを保存
      const sessionRef = db.collection('users').doc(userId)
                          .collection('sleepSessions').doc();
      transaction.set(sessionRef, {
        ...sleepSession,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        userId: userId
      });

      // 2. 日次集計データを更新
      const date = new Date(sleepSession.startTime).toISOString().split('T')[0];
      const dailyRef = db.collection('users').doc(userId)
                        .collection('dailyAggregates').doc(date);
      
      const dailyAggregate = calculateDailyAggregate(sleepSession);
      transaction.set(dailyRef, dailyAggregate, { merge: true });

      // 3. 匿名化データをグループ統計に追加
      const anonymizedData = anonymizeSleepData(sleepSession, userProfile);
      const groupKey = `${userProfile.ageGroup}-${userProfile.occupation}`;
      const groupRef = db.collection('analytics').doc('groupStats')
                        .collection('data').doc(groupKey);
      
      transaction.update(groupRef, {
        totalSessions: admin.firestore.FieldValue.increment(1),
        avgDuration: updateRunningAverage(anonymizedData.duration),
        lastUpdated: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    return { success: true, message: 'データが正常にアップロードされました' };
  } catch (error) {
    console.error('アップロードエラー:', error);
    throw new functions.https.HttpsError('internal', 'データの保存に失敗しました');
  }
});
```

#### 2.2 データ匿名化処理
```javascript
function anonymizeSleepData(sleepSession, userProfile) {
  return {
    duration: sleepSession.duration,
    quality: sleepSession.qualityScore,
    ageGroup: userProfile.ageGroup,
    occupation: userProfile.occupation,
    phoneUsageTime: userProfile.phoneUsageTime,
    dayType: getDayType(new Date(sleepSession.startTime)),
    // 個人識別情報は除外
  };
}
```

### フェーズ3: グループ分析API（1週間）

#### 3.1 グループ統計取得関数
```javascript
// functions/src/getGroupAnalytics.js
exports.getGroupAnalytics = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'ユーザー認証が必要です');
  }

  const { ageGroup, occupation } = data;
  const db = admin.firestore();

  try {
    // グループ統計を取得
    const groupKey = `${ageGroup}-${occupation}`;
    const groupStatsDoc = await db.collection('analytics')
                                 .doc('groupStats')
                                 .collection('data')
                                 .doc(groupKey)
                                 .get();

    if (!groupStatsDoc.exists) {
      return {
        ageGroup,
        occupation,
        avgSleepDuration: 0,
        avgSleepQuality: 0,
        sampleSize: 0,
        message: 'データが不足しています'
      };
    }

    const stats = groupStatsDoc.data();
    
    return {
      ageGroup,
      occupation,
      avgSleepDuration: stats.avgDuration || 0,
      avgSleepQuality: stats.avgQuality || 0,
      sampleSize: stats.totalSessions || 0,
      phoneUsageImpact: stats.phoneUsageCorrelation || null,
      lastUpdated: stats.lastUpdated
    };
  } catch (error) {
    console.error('グループ分析エラー:', error);
    throw new functions.https.HttpsError('internal', '分析データの取得に失敗しました');
  }
});
```

#### 3.2 トレンド分析関数
```javascript
exports.getTrendAnalytics = functions.https.onCall(async (data, context) => {
  const { period = '30days' } = data;
  const db = admin.firestore();

  try {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - parseInt(period.replace('days', '')));

    const trendsQuery = await db.collection('analytics')
                              .doc('trends')
                              .collection('daily')
                              .where('date', '>=', startDate.toISOString().split('T')[0])
                              .where('date', '<=', endDate.toISOString().split('T')[0])
                              .orderBy('date')
                              .get();

    const trends = trendsQuery.docs.map(doc => ({
      date: doc.id,
      ...doc.data()
    }));

    return {
      period,
      trends,
      summary: calculateTrendSummary(trends)
    };
  } catch (error) {
    console.error('トレンド分析エラー:', error);
    throw new functions.https.HttpsError('internal', 'トレンド分析に失敗しました');
  }
});
```

### フェーズ4: Flutter統合（1週間）

#### 4.1 Firebase SDK設定
```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  cloud_functions: ^4.6.4
```

#### 4.2 Firebase設定ファイル
```dart
// lib/services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // 匿名認証
  static Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print('匿名認証エラー: $e');
      return null;
    }
  }

  // 睡眠データアップロード
  static Future<bool> uploadSleepData(Map<String, dynamic> sleepSession) async {
    try {
      final callable = _functions.httpsCallable('uploadSleepData');
      final result = await callable.call({
        'sleepSession': sleepSession,
      });
      
      return result.data['success'] == true;
    } catch (e) {
      print('データアップロードエラー: $e');
      return false;
    }
  }

  // グループ分析取得
  static Future<Map<String, dynamic>?> getGroupAnalytics({
    required String ageGroup,
    required String occupation,
  }) async {
    try {
      final callable = _functions.httpsCallable('getGroupAnalytics');
      final result = await callable.call({
        'ageGroup': ageGroup,
        'occupation': occupation,
      });
      
      return result.data;
    } catch (e) {
      print('グループ分析取得エラー: $e');
      return null;
    }
  }
}
```

#### 4.3 サーバーレス分析プロバイダー
```dart
// lib/presentation/providers/serverless_analytics_provider.dart
import 'package:flutter/foundation.dart';
import '../../services/firebase_service.dart';
import '../../domain/entities/user_profile.dart';

class ServerlessAnalyticsProvider with ChangeNotifier {
  Map<String, dynamic>? _groupAnalytics;
  Map<String, dynamic>? _trendAnalytics;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get groupAnalytics => _groupAnalytics;
  Map<String, dynamic>? get trendAnalytics => _trendAnalytics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // グループ比較データを取得
  Future<void> loadGroupAnalytics(UserProfile userProfile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await FirebaseService.getGroupAnalytics(
        ageGroup: userProfile.ageGroup ?? '',
        occupation: userProfile.occupation ?? '',
      );

      _groupAnalytics = result;
    } catch (e) {
      _errorMessage = 'グループ分析の取得に失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 睡眠データをサーバーにアップロード
  Future<bool> uploadSleepSession(Map<String, dynamic> sleepSession) async {
    try {
      return await FirebaseService.uploadSleepData(sleepSession);
    } catch (e) {
      _errorMessage = 'データのアップロードに失敗しました: $e';
      notifyListeners();
      return false;
    }
  }
}
```

## セキュリティ設計

### Firebase Security Rules
```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 分析データは認証済みユーザーのみ読み取り可能
    match /analytics/{document=**} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud Functionsからのみ書き込み可能
    }
  }
}
```

### Cloud Functions セキュリティ
```javascript
// 入力データバリデーション
function validateSleepSession(data) {
  const required = ['startTime', 'endTime', 'duration', 'qualityScore'];
  
  for (const field of required) {
    if (!(field in data)) {
      throw new functions.https.HttpsError('invalid-argument', `${field}は必須です`);
    }
  }

  // データ型チェック
  if (typeof data.duration !== 'number' || data.duration < 0) {
    throw new functions.https.HttpsError('invalid-argument', '睡眠時間が無効です');
  }

  if (typeof data.qualityScore !== 'number' || data.qualityScore < 0 || data.qualityScore > 100) {
    throw new functions.https.HttpsError('invalid-argument', '睡眠品質スコアが無効です');
  }
}
```

## コスト見積もり

### 月額コスト（1000ユーザー想定）
```
Cloud Functions:
- 呼び出し回数: 30,000回/月 → $0 (無料枠内)
- 実行時間: 100GB秒/月 → $0 (無料枠内)

Firestore:
- 読み取り: 100,000回/月 → $0 (無料枠内)
- 書き込み: 50,000回/月 → $0 (無料枠内)
- ストレージ: 5GB → $0 (無料枠内)

Firebase Auth:
- 匿名認証 → 無料

合計: 月額 $0-2 (約0-300円)
```

## デプロイメント

### 自動デプロイ設定
```yaml
# .github/workflows/deploy-functions.yml
name: Deploy Cloud Functions
on:
  push:
    branches: [main]
    paths: ['functions/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: cd functions && npm install
      
      - name: Deploy to Firebase
        run: |
          npm install -g firebase-tools
          firebase deploy --only functions
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
```

## モニタリング

### Cloud Logging設定
```javascript
const { Logging } = require('@google-cloud/logging');
const logging = new Logging();

function logAnalyticsEvent(eventType, data) {
  const log = logging.log('sleep-analytics');
  const metadata = {
    resource: { type: 'cloud_function' },
    severity: 'INFO',
  };

  const entry = log.entry(metadata, {
    eventType,
    timestamp: new Date().toISOString(),
    data
  });

  log.write(entry);
}
```

## 次のステップ

1. **Google Cloud プロジェクト作成**
2. **Firebase プロジェクト初期化**
3. **Cloud Functions 開発環境セットアップ**
4. **Firestore セキュリティルール設定**
5. **Flutter アプリへのFirebase SDK統合**
6. **段階的デプロイとテスト**

この構成により、月額数百円から1000円程度で高可用性なサーバーレス分析システムを構築できます。