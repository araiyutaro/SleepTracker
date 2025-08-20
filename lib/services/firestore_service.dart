import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../domain/entities/sleep_session.dart';
import '../domain/entities/user_profile.dart';
import '../domain/entities/sleep_literacy_test.dart';
import '../config/flavor_config.dart';
import 'firebase_service.dart';

/// Firestoreへのデータ永続化を管理するサービス
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  FirebaseFirestore? _firestore;
  String? _currentUserId;
  
  /// Firestoreが初期化されているか
  bool get isInitialized => _firestore != null && _currentUserId != null;

  /// Firestoreを初期化
  Future<void> initialize() async {
    if (!FirebaseService.isInitialized) {
      debugPrint('FirestoreService: Firebase not initialized, skipping Firestore setup');
      return;
    }

    try {
      _firestore = FirebaseFirestore.instance;
      
      // Dev環境ではローカルエミュレーターを使用（オプション）
      if (FlavorConfig.isDev) {
        // エミュレーターを使用する場合はコメントアウトを解除
        // _firestore.useFirestoreEmulator('localhost', 8080);
        
        // デバッグ用の設定
        _firestore!.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }
      
      // Firebase Authから現在のユーザーを取得
      final currentUser = FirebaseService.getCurrentUser();
      
      if (currentUser == null) {
        // ユーザーがログインしていない場合、匿名認証を実行
        debugPrint('🔄 No user logged in, attempting anonymous authentication...');
        final userCredential = await FirebaseService.signInAnonymously();
        
        if (userCredential?.user != null) {
          _currentUserId = userCredential!.user!.uid;
        } else {
          // 匿名認証に失敗した場合のフォールバック
          _currentUserId = 'anonymous_user_${DateTime.now().millisecondsSinceEpoch}';
          debugPrint('⚠️ Failed to authenticate, using fallback user ID');
        }
      } else {
        _currentUserId = currentUser.uid;
      }
      
      // 認証状態の変化を監視
      FirebaseService.authStateChanges().listen((user) {
        if (user != null) {
          _currentUserId = user.uid;
          debugPrint('🔄 User ID updated: $_currentUserId');
        }
      });
      
      debugPrint('✅ FirestoreService initialized');
      debugPrint('Current user ID: $_currentUserId');
      
      // Firebase Auth状態の詳細ログ
      final authUser = FirebaseService.getCurrentUser();
      debugPrint('Firebase Auth user: ${authUser?.uid}');
      debugPrint('Firebase Auth anonymous: ${authUser?.isAnonymous}');
      debugPrint('Firebase Auth providers: ${authUser?.providerData.length}');
    } catch (e) {
      debugPrint('❌ FirestoreService initialization failed: $e');
      rethrow;
    }
  }

  /// ユーザープロフィールを保存
  Future<void> saveUserProfile(UserProfile profile) async {
    if (!isInitialized) {
      debugPrint('FirestoreService not initialized');
      return;
    }

    try {
      // 認証状態を再確認
      final currentAuthUser = FirebaseService.getCurrentUser();
      debugPrint('🔍 Saving profile - Auth user: ${currentAuthUser?.uid}');
      debugPrint('🔍 Saving profile - Profile ID: ${profile.id}');
      debugPrint('🔍 Saving profile - Current user ID: $_currentUserId');
      
      if (currentAuthUser == null) {
        debugPrint('⚠️ No authenticated user found, attempting anonymous auth...');
        final userCredential = await FirebaseService.signInAnonymously();
        if (userCredential?.user != null) {
          _currentUserId = userCredential!.user!.uid;
          debugPrint('✅ Anonymous auth successful: $_currentUserId');
        } else {
          throw Exception('Failed to authenticate user');
        }
      }
      
      // Firebase AuthのUIDをFirestoreのドキュメントIDとして使用
      // これによりセキュリティルールが正常に動作します
      await _firestore!
          .collection('users')
          .doc(_currentUserId!)
          .set({
        'firebaseUid': _currentUserId, // Firebase AuthのUID（ドキュメントIDと同じ）
        'profileId': profile.id, // UserProfileのUUID
        'nickname': profile.nickname,
        'ageGroup': profile.ageGroup,
        'gender': profile.gender,
        'occupation': profile.occupation,
        'targetSleepHours': profile.targetSleepHours,
        'targetBedtime': '${profile.targetBedtime.hour}:${profile.targetBedtime.minute}',
        'targetWakeTime': '${profile.targetWakeTime.hour}:${profile.targetWakeTime.minute}',
        'sleepConcerns': profile.sleepConcerns,
        'caffeineHabit': profile.caffeineHabit,
        'alcoholHabit': profile.alcoholHabit,
        'exerciseHabit': profile.exerciseHabit,
        'phoneUsageTime': profile.phoneUsageTime,
        'phoneUsageContent': profile.phoneUsageContent,
        'isOnboardingCompleted': profile.isOnboardingCompleted,
        'sleepLiteracyScore': profile.sleepLiteracyScore,
        'sleepLiteracyTestDate': profile.sleepLiteracyTestDate != null 
            ? Timestamp.fromDate(profile.sleepLiteracyTestDate!) 
            : null,
        'sleepLiteracyTestDurationMinutes': profile.sleepLiteracyTestDurationMinutes,
        'sleepLiteracyCategoryScores': profile.sleepLiteracyCategoryScores,
        'createdAt': Timestamp.fromDate(profile.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ User profile saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save user profile: $e');
      // エラーが発生してもローカル動作は継続
    }
  }

  /// 睡眠セッションを保存
  Future<void> saveSleepSession(SleepSession session) async {
    if (!isInitialized) {
      debugPrint('FirestoreService not initialized');
      return;
    }

    try {
      final sessionData = {
        'id': session.id, // セッションID
        'userId': _currentUserId, // 現在のユーザーID（Firebase Auth）
        'startTime': Timestamp.fromDate(session.startTime),
        'endTime': session.endTime != null ? Timestamp.fromDate(session.endTime!) : null,
        'duration': session.duration?.inMinutes,
        'qualityScore': session.qualityScore,
        'wakeQuality': session.wakeQuality,
        'phoneUsageBeforeSleep': session.phoneUsageBeforeSleep, // 就寝前のスマホ利用時間（分）
        'isActive': session.isActive,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 睡眠ステージデータがある場合は追加
      if (session.sleepStages != null) {
        sessionData['sleepStages'] = {
          'deepSleepPercentage': session.sleepStages!.deepSleepPercentage,
          'lightSleepPercentage': session.sleepStages!.lightSleepPercentage,
          'remSleepPercentage': session.sleepStages!.remSleepPercentage,
          'awakePercentage': session.sleepStages!.awakePercentage,
          'movementCount': session.sleepStages!.movementCount,
        };
      }
      
      // 動きデータがある場合は追加
      if (session.movements.isNotEmpty) {
        sessionData['movements'] = session.movements.map((movement) => {
          'timestamp': Timestamp.fromDate(movement.timestamp),
          'intensity': movement.intensity,
        }).toList();
      }

      await _firestore!
          .collection('users')
          .doc(_currentUserId)
          .collection('sleepSessions')
          .doc(session.id)
          .set(sessionData);
      
      
      // 日次集計データも更新
      if (session.endTime != null) {
        await _updateDailyAggregate(session);
      }
    } catch (e) {
      debugPrint('❌ Failed to save sleep session: $e');
    }
  }

  /// 睡眠リテラシーテスト結果を保存
  Future<void> saveTestResult(SleepLiteracyTest test) async {
    if (!isInitialized) {
      debugPrint('FirestoreService not initialized');
      return;
    }

    try {
      final testData = {
        'userId': _currentUserId, // 現在のユーザーID（Firebase Auth）
        'startTime': Timestamp.fromDate(test.startTime),
        'endTime': test.endTime != null ? Timestamp.fromDate(test.endTime!) : null,
        'score': test.score,
        'totalQuestions': test.questions.length,
        'answeredCount': test.answeredCount,
        'unknownAnswersCount': test.unknownAnswersCount,
        'durationMinutes': test.durationMinutes,
        'categoryScores': test.categoryScores,
        'answers': test.answers,
        'isCompleted': test.isCompleted,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // テストIDをタイムスタンプから生成
      final testId = '${test.startTime.millisecondsSinceEpoch}';
      
      await _firestore!
          .collection('users')
          .doc(_currentUserId)
          .collection('testResults')
          .doc(testId)
          .set(testData);
      
      debugPrint('✅ Test result saved to Firestore: $testId');
    } catch (e) {
      debugPrint('❌ Failed to save test result: $e');
    }
  }

  /// アンケート回答を保存
  Future<void> saveSurveyResponse(String surveyType, Map<String, dynamic> responses) async {
    if (!isInitialized) {
      debugPrint('FirestoreService not initialized');
      return;
    }

    try {
      final surveyData = {
        'surveyType': surveyType,
        'responses': responses,
        'completedAt': FieldValue.serverTimestamp(),
      };

      await _firestore!
          .collection('users')
          .doc(_currentUserId)
          .collection('surveyResponses')
          .add(surveyData);
      
      debugPrint('✅ Survey response saved to Firestore: $surveyType');
    } catch (e) {
      debugPrint('❌ Failed to save survey response: $e');
    }
  }

  /// 日次集計データを更新（プライベートメソッド）
  Future<void> _updateDailyAggregate(SleepSession session) async {
    try {
      final date = '${session.startTime.year}-${session.startTime.month.toString().padLeft(2, '0')}-${session.startTime.day.toString().padLeft(2, '0')}';
      final aggregateId = '${_currentUserId}_$date';
      
      final aggregateRef = _firestore!
          .collection('dailyAggregates')
          .doc(aggregateId);
      
      await _firestore!.runTransaction((transaction) async {
        final snapshot = await transaction.get(aggregateRef);
        
        if (snapshot.exists) {
          // 既存の集計データを更新
          final data = snapshot.data()!;
          final currentTotal = data['totalSleep'] as int;
          final currentCount = data['sessionsCount'] as int;
          final currentQualitySum = (data['qualitySum'] ?? 0) as num;
          
          transaction.update(aggregateRef, {
            'totalSleep': currentTotal + (session.duration?.inMinutes ?? 0),
            'sessionsCount': currentCount + 1,
            'qualitySum': currentQualitySum + (session.qualityScore ?? 0),
            'avgQuality': (currentQualitySum + (session.qualityScore ?? 0)) / (currentCount + 1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // 新規作成
          transaction.set(aggregateRef, {
            'userId': _currentUserId,
            'date': date,
            'totalSleep': session.duration?.inMinutes ?? 0,
            'sessionsCount': 1,
            'qualitySum': session.qualityScore ?? 0,
            'avgQuality': session.qualityScore ?? 0,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });
      
    } catch (e) {
      debugPrint('❌ Failed to update daily aggregate: $e');
    }
  }

  /// ユーザーデータをFirestoreから取得（オプション）
  Future<Map<String, dynamic>?> getUserData() async {
    if (!isInitialized) return null;

    try {
      final doc = await _firestore!
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      return doc.data();
    } catch (e) {
      debugPrint('❌ Failed to get user data: $e');
      return null;
    }
  }

  /// 睡眠セッションを取得（期間指定）
  Future<List<Map<String, dynamic>>> getSleepSessions({
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    if (!isInitialized) return [];

    try {
      Query query = _firestore!
          .collection('users')
          .doc(_currentUserId)
          .collection('sleepSessions')
          .orderBy('startTime', descending: true);
      
      if (startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      
      if (endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      debugPrint('❌ Failed to get sleep sessions: $e');
      return [];
    }
  }
}