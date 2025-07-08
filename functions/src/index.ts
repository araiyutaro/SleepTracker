import {onCall, HttpsError} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue, Timestamp} from "firebase-admin/firestore";

initializeApp();

const db = getFirestore();

// 睡眠データアップロード関数
export const uploadSleepData = onCall(async (request) => {
  // 認証チェック
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "ユーザー認証が必要です");
  }

  const userId = request.auth.uid;
  const {sleepSession, userProfile} = request.data;

  // 入力データ検証
  validateSleepSession(sleepSession);

  try {
    // Firestore トランザクション
    await db.runTransaction(async (transaction) => {
      // 1. 睡眠セッションを保存
      const sessionRef = db.collection("users").doc(userId)
        .collection("sleepSessions").doc();
      
      transaction.set(sessionRef, {
        ...sleepSession,
        createdAt: FieldValue.serverTimestamp(),
        userId: userId,
      });

      // 2. 日次集計データを更新
      const startDate = new Date(sleepSession.startTime);
      const dateStr = startDate.toISOString().split("T")[0];
      const dailyRef = db.collection("users").doc(userId)
        .collection("dailyAggregates").doc(dateStr);

      const dailyAggregate = calculateDailyAggregate(sleepSession, startDate);
      transaction.set(dailyRef, dailyAggregate, {merge: true});

      // 3. 匿名化データをグループ統計に追加
      if (userProfile) {
        const anonymizedData = anonymizeSleepData(sleepSession, userProfile);
        await updateGroupStatistics(transaction, anonymizedData);
      }
    });

    return {success: true, message: "データが正常にアップロードされました"};
  } catch (error) {
    console.error("アップロードエラー:", error);
    throw new HttpsError("internal", "データの保存に失敗しました");
  }
});

// グループ分析取得関数
export const getGroupAnalytics = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "ユーザー認証が必要です");
  }

  const {ageGroup, occupation} = request.data;

  if (!ageGroup || !occupation) {
    throw new HttpsError("invalid-argument", "年齢グループと職業は必須です");
  }

  try {
    // グループ統計を取得
    const groupKey = `${ageGroup}-${occupation}`;
    const groupStatsDoc = await db.collection("groupStats").doc(groupKey).get();

    if (!groupStatsDoc.exists) {
      return {
        ageGroup,
        occupation,
        avgSleepDuration: 0,
        avgSleepQuality: 0,
        sampleSize: 0,
        message: "データが不足しています",
      };
    }

    const stats = groupStatsDoc.data()!;

    return {
      ageGroup,
      occupation,
      avgSleepDuration: stats.avgDuration || 0,
      avgSleepQuality: stats.avgQuality || 0,
      sampleSize: stats.totalSessions || 0,
      phoneUsageImpact: stats.phoneUsageCorrelation || null,
      lastUpdated: stats.lastUpdated,
    };
  } catch (error) {
    console.error("グループ分析エラー:", error);
    throw new HttpsError("internal", "分析データの取得に失敗しました");
  }
});

// トレンド分析取得関数
export const getTrendAnalytics = onCall(async (request) => {
  const {period = "30"} = request.data;
  const periodDays = parseInt(period);

  if (isNaN(periodDays) || periodDays < 1 || periodDays > 365) {
    throw new HttpsError("invalid-argument", "期間は1-365日で指定してください");
  }

  try {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(endDate.getDate() - periodDays);

    const trendsQuery = await db.collection("analytics")
      .doc("trends")
      .collection("daily")
      .where("date", ">=", startDate.toISOString().split("T")[0])
      .where("date", "<=", endDate.toISOString().split("T")[0])
      .orderBy("date")
      .get();

    const trends = trendsQuery.docs.map((doc) => ({
      date: doc.id,
      ...doc.data(),
    }));

    return {
      period: `${periodDays}days`,
      trends,
      summary: calculateTrendSummary(trends),
    };
  } catch (error) {
    console.error("トレンド分析エラー:", error);
    throw new HttpsError("internal", "トレンド分析に失敗しました");
  }
});

// ヘルパー関数群

function validateSleepSession(sleepSession: any) {
  const required = ["startTime", "endTime", "duration", "qualityScore"];

  for (const field of required) {
    if (!(field in sleepSession)) {
      throw new HttpsError("invalid-argument", `${field}は必須です`);
    }
  }

  // データ型チェック
  if (typeof sleepSession.duration !== "number" || sleepSession.duration < 0) {
    throw new HttpsError("invalid-argument", "睡眠時間が無効です");
  }

  if (typeof sleepSession.qualityScore !== "number" ||
      sleepSession.qualityScore < 0 || sleepSession.qualityScore > 100) {
    throw new HttpsError("invalid-argument", "睡眠品質スコアが無効です");
  }
}

function calculateDailyAggregate(sleepSession: any, date: Date) {
  const dayType = (date.getDay() === 0 || date.getDay() === 6) ? "weekend" : "weekday";

  return {
    userId: sleepSession.userId,
    date: date.toISOString().split("T")[0],
    sleepDuration: sleepSession.duration,
    sleepQuality: sleepSession.qualityScore,
    bedtime: new Date(sleepSession.startTime),
    wakeTime: new Date(sleepSession.endTime),
    movementCount: sleepSession.movements?.length || 0,
    dayType,
    createdAt: FieldValue.serverTimestamp(),
  };
}

function anonymizeSleepData(sleepSession: any, userProfile: any) {
  const startDate = new Date(sleepSession.startTime);
  const dayType = (startDate.getDay() === 0 || startDate.getDay() === 6) ? "weekend" : "weekday";

  return {
    duration: sleepSession.duration,
    quality: sleepSession.qualityScore,
    ageGroup: userProfile.ageGroup,
    occupation: userProfile.occupation,
    phoneUsageTime: userProfile.phoneUsageTime,
    dayType,
    timestamp: Timestamp.now(),
  };
}

async function updateGroupStatistics(transaction: any, anonymizedData: any) {
  const groupKey = `${anonymizedData.ageGroup}-${anonymizedData.occupation}`;
  const groupRef = db.collection("groupStats").doc(groupKey);

  const groupDoc = await transaction.get(groupRef);

  if (groupDoc.exists) {
    const currentStats = groupDoc.data()!;
    const newCount = (currentStats.totalSessions || 0) + 1;
    
    // 移動平均を計算
    const newAvgDuration = calculateMovingAverage(
      currentStats.avgDuration || 0,
      anonymizedData.duration,
      currentStats.totalSessions || 0
    );
    
    const newAvgQuality = calculateMovingAverage(
      currentStats.avgQuality || 0,
      anonymizedData.quality,
      currentStats.totalSessions || 0
    );

    transaction.update(groupRef, {
      totalSessions: newCount,
      avgDuration: newAvgDuration,
      avgQuality: newAvgQuality,
      lastUpdated: FieldValue.serverTimestamp(),
    });
  } else {
    transaction.set(groupRef, {
      ageGroup: anonymizedData.ageGroup,
      occupation: anonymizedData.occupation,
      totalSessions: 1,
      avgDuration: anonymizedData.duration,
      avgQuality: anonymizedData.quality,
      createdAt: FieldValue.serverTimestamp(),
      lastUpdated: FieldValue.serverTimestamp(),
    });
  }
}

function calculateMovingAverage(currentAvg: number, newValue: number, count: number): number {
  if (count === 0) return newValue;
  return (currentAvg * count + newValue) / (count + 1);
}

function calculateTrendSummary(trends: any[]): any {
  if (trends.length === 0) {
    return {
      avgDuration: 0,
      avgQuality: 0,
      trend: "insufficient_data",
    };
  }

  const totalDuration = trends.reduce((sum, trend) => sum + (trend.avgDuration || 0), 0);
  const totalQuality = trends.reduce((sum, trend) => sum + (trend.avgQuality || 0), 0);

  return {
    avgDuration: totalDuration / trends.length,
    avgQuality: totalQuality / trends.length,
    trend: trends.length > 1 ? calculateTrend(trends) : "insufficient_data",
    dataPoints: trends.length,
  };
}

function calculateTrend(trends: any[]): string {
  if (trends.length < 2) return "insufficient_data";

  const firstHalf = trends.slice(0, Math.floor(trends.length / 2));
  const secondHalf = trends.slice(Math.floor(trends.length / 2));

  const firstAvg = firstHalf.reduce((sum, trend) => sum + (trend.avgQuality || 0), 0) / firstHalf.length;
  const secondAvg = secondHalf.reduce((sum, trend) => sum + (trend.avgQuality || 0), 0) / secondHalf.length;

  const difference = secondAvg - firstAvg;
  
  if (Math.abs(difference) < 2) return "stable";
  return difference > 0 ? "improving" : "declining";
}