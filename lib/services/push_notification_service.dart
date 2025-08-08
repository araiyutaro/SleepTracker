import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/analytics_service.dart';
import '../services/firebase_service.dart';
import '../app.dart';
import '../presentation/screens/main_screen.dart';

// バックグラウンドメッセージハンドラー（トップレベル関数である必要がある）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
  
  // バックグラウンドでの処理（必要に応じて）
  if (message.notification != null) {
    debugPrint('Background notification: ${message.notification!.title}');
  }
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  bool _isInitialized = false;

  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;

  /// プッシュ通知サービスを初期化
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Firebaseが初期化されていない場合はスキップ
    if (!FirebaseService.isInitialized) {
      debugPrint('PushNotificationService: Firebase not initialized, skipping push notification setup');
      print('❌ Firebase is not initialized - PushNotificationService cannot start');
      print('Make sure Firebase config files are in place:');
      print('  - android/app/google-services.json');
      print('  - ios/Runner/GoogleService-Info.plist');
      return;
    }
    
    // iOSで開発者アカウントの制限チェック
    try {
      // Firebase Messagingの初期化を試行
      await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('⚠️ Push notification setup failed (likely due to iOS development team limitations): $e');
      print('⚠️ Push notifications are not available in development mode');
      print('This is expected when using a Personal Development Team (free Apple Developer account)');
      print('To enable push notifications:');
      print('  1. Join the Apple Developer Program (\$99/year)');
      print('  2. Or test on Android where Firebase Cloud Messaging works with free accounts');
      return;
    }
    
    debugPrint('PushNotificationService: Firebase is initialized, starting push notification setup');

    try {
      // バックグラウンドメッセージハンドラーを設定
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 通知権限をリクエスト
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('Push notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // FCMトークンを取得
        _fcmToken = await _firebaseMessaging.getToken();
        debugPrint('=== FCM TOKEN FOR PUSH NOTIFICATIONS ===');
        debugPrint('FCM Token: $_fcmToken');
        debugPrint('========================================');
        
        // メッセージ送信用にも出力
        print('📱 FCM Token for sending push notifications:');
        print('$_fcmToken');
        print('Copy this token to send test messages from Firebase Console');

        // ローカル通知を初期化
        await _initializeLocalNotifications();

        // メッセージリスナーを設定
        _setupMessageListeners();

        _isInitialized = true;

        // Analytics: プッシュ通知初期化イベント
        await AnalyticsService().logCustomEvent('push_notification_initialized', parameters: {
          'permission_status': settings.authorizationStatus.toString(),
          'has_token': _fcmToken != null,
        });
      } else {
        debugPrint('Push notification permission denied');
        
        // Analytics: 権限拒否イベント
        await AnalyticsService().logCustomEvent('push_notification_permission_denied');
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
      
      // Analytics: 初期化エラー
      await AnalyticsService().logError('push_notification_init_error', e.toString());
    }
  }

  /// ローカル通知を初期化
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // FCMで既にリクエスト済み
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// メッセージリスナーを設定
  void _setupMessageListeners() {
    // フォアグラウンドでメッセージを受信した時
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 通知をタップしてアプリを開いた時
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // アプリが終了状態から通知で起動された場合の処理
    _handleInitialMessage();

    // トークンが更新された時
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      debugPrint('=== FCM TOKEN REFRESHED ===');
      debugPrint('New FCM Token: $token');
      debugPrint('==========================');
      
      // メッセージ送信用にも出力
      print('🔄 FCM Token has been refreshed:');
      print('$token');
      print('Update this token if sending messages from external services');
      
      // Analytics: トークン更新イベント
      AnalyticsService().logCustomEvent('fcm_token_refreshed', parameters: {
        'new_token_length': token.length,
      });
    });
  }

  /// フォアグラウンドでメッセージを受信した時の処理
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');
    
    // Analytics: フォアグラウンドメッセージ受信
    await AnalyticsService().logCustomEvent('push_notification_received_foreground', parameters: {
      'message_id': message.messageId ?? 'unknown',
      'has_notification': message.notification != null,
      'has_data': message.data.isNotEmpty,
    });

    if (message.notification != null) {
      // フォアグラウンドでもローカル通知として表示
      await _showLocalNotification(message);
    }

    // データメッセージの処理
    if (message.data.isNotEmpty) {
      await _handleDataMessage(message.data);
    }
  }

  /// 通知をタップしてアプリを開いた時の処理
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('Message opened app: ${message.messageId}');
    
    // Analytics: 通知タップでアプリ起動
    await AnalyticsService().logCustomEvent('push_notification_opened_app', parameters: {
      'message_id': message.messageId ?? 'unknown',
      'notification_title': message.notification?.title ?? '',
    });

    // 必要に応じて特定の画面に遷移
    await _navigateBasedOnMessage(message);
  }

  /// アプリが終了状態から通知で起動された場合の処理
  Future<void> _handleInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
      
      // Analytics: 通知からアプリ起動
      await AnalyticsService().logCustomEvent('push_notification_launched_app', parameters: {
        'message_id': initialMessage.messageId ?? 'unknown',
        'notification_title': initialMessage.notification?.title ?? '',
      });

      await _navigateBasedOnMessage(initialMessage);
    }
  }

  /// ローカル通知を表示
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'push_notifications',
      'プッシュ通知',
      channelDescription: 'サーバーからのプッシュ通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: const Color(0xFF4A90E2),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode, // 一意のID
      notification.title,
      notification.body,
      details,
      payload: message.data.isNotEmpty ? message.data.toString() : null,
    );
  }

  /// データメッセージの処理
  Future<void> _handleDataMessage(Map<String, dynamic> data) async {
    debugPrint('Handling data message: $data');

    final type = data['type'] as String?;
    
    switch (type) {
      case 'sleep_reminder':
        // 睡眠リマインダーの処理
        await _handleSleepReminder(data);
        break;
      case 'sleep_tip':
        // 睡眠のコツの処理
        await _handleSleepTip(data);
        break;
      case 'weekly_report':
        // 週間レポートの処理
        await _handleWeeklyReport(data);
        break;
      default:
        debugPrint('Unknown data message type: $type');
    }

    // Analytics: データメッセージ処理
    await AnalyticsService().logCustomEvent('push_notification_data_processed', parameters: {
      'message_type': type ?? 'unknown',
      'data_keys': data.keys.join(','),
    });
  }

  /// メッセージに基づいた画面遷移
  Future<void> _navigateBasedOnMessage(RemoteMessage message) async {
    debugPrint('Navigation based on message: ${message.data}');
    
    // Navigatorが利用可能になるまで待つ
    await Future.delayed(const Duration(milliseconds: 100));
    
    final navigatorState = SleepApp.navigatorKey.currentState;
    if (navigatorState == null) {
      debugPrint('Navigator is not available yet');
      // Navigatorが利用できない場合は、さらに待ってリトライ
      await Future.delayed(const Duration(seconds: 1));
      if (SleepApp.navigatorKey.currentState != null) {
        _performNavigation(SleepApp.navigatorKey.currentState!, message);
      } else {
        debugPrint('Failed to navigate - Navigator not available');
      }
    } else {
      _performNavigation(navigatorState, message);
    }
  }
  
  /// 実際の画面遷移を実行
  void _performNavigation(NavigatorState navigator, RemoteMessage message) {
    debugPrint('Performing navigation for message type: ${message.data['type']}');
    
    // データタイプに基づいて適切な画面に遷移
    final type = message.data['type'] as String?;
    
    switch (type) {
      case 'sleep_reminder':
        // メイン画面に遷移してスリープボタンを強調
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
        break;
      case 'sleep_tip':
        // メイン画面の統計タブに遷移
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 2)),
          (route) => false,
        );
        break;
      case 'weekly_report':
        // メイン画面の履歴タブに遷移
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen(initialIndex: 1)),
          (route) => false,
        );
        break;
      default:
        // デフォルトはメイン画面
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
    }
  }

  /// 睡眠リマインダーの処理
  Future<void> _handleSleepReminder(Map<String, dynamic> data) async {
    debugPrint('Processing sleep reminder: $data');
    // 必要に応じて特定の処理を実装
  }

  /// 睡眠のコツの処理
  Future<void> _handleSleepTip(Map<String, dynamic> data) async {
    debugPrint('Processing sleep tip: $data');
    // 必要に応じて特定の処理を実装
  }

  /// 週間レポートの処理
  Future<void> _handleWeeklyReport(Map<String, dynamic> data) async {
    debugPrint('Processing weekly report: $data');
    // 必要に応じて特定の処理を実装
  }

  /// ローカル通知がタップされた時の処理
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    // Analytics: ローカル通知タップ
    AnalyticsService().logCustomEvent('local_notification_tapped', parameters: {
      'notification_id': response.id ?? 0,
      'has_payload': response.payload != null,
    });
  }

  /// 特定のトピックに購読
  Future<void> subscribeToTopic(String topic) async {
    try {
      // iOSでFCMトークンが無い場合はスキップ
      if (Platform.isIOS && _fcmToken == null) {
        debugPrint('⚠️ Skipping topic subscription - FCM token not available on iOS');
        return;
      }
      
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
      
      // Analytics: トピック購読
      await AnalyticsService().logCustomEvent('push_notification_topic_subscribed', parameters: {
        'topic': topic,
      });
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topic $topic: $e');
      // APNSトークンエラーの場合は警告のみ
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('⚠️ This is expected when using a Personal Development Team');
      }
    }
  }

  /// 特定のトピックから購読解除
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // iOSでFCMトークンが無い場合はスキップ
      if (Platform.isIOS && _fcmToken == null) {
        debugPrint('⚠️ Skipping topic unsubscription - FCM token not available on iOS');
        return;
      }
      
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
      
      // Analytics: トピック購読解除
      await AnalyticsService().logCustomEvent('push_notification_topic_unsubscribed', parameters: {
        'topic': topic,
      });
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topic $topic: $e');
      // APNSトークンエラーの場合は警告のみ
      if (e.toString().contains('apns-token-not-set')) {
        debugPrint('⚠️ This is expected when using a Personal Development Team');
      }
    }
  }

  /// テスト用の通知を送信（開発時のデバッグ用）
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      debugPrint('Push notification service not initialized');
      throw Exception('プッシュ通知サービスが初期化されていません');
    }

    // 通知権限を確認
    final status = await getPermissionStatus();
    if (status != AuthorizationStatus.authorized && status != AuthorizationStatus.provisional) {
      throw Exception('通知許可が必要です');
    }

    try {
      // ローカル通知でテスト（フォアグラウンドでもプッシュ通知のテストとして表示）
      const androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'テスト通知',
        channelDescription: '開発時のテスト用通知',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: Color(0xFF4A90E2),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _localNotifications.show(
        notificationId,
        '✅ テスト通知成功',
        'プッシュ通知サービスが正常に動作しています。FCM Token: ${_fcmToken?.substring(0, 8)}...',
        details,
        payload: 'test_notification',
      );

      debugPrint('Test notification sent successfully with ID: $notificationId');
      
      // Analytics: テスト通知送信
      await AnalyticsService().logCustomEvent('push_notification_test_sent', parameters: {
        'notification_id': notificationId,
        'has_token': _fcmToken != null,
        'permission_status': status.toString(),
      });
    } catch (e) {
      debugPrint('Failed to send test notification: $e');
      
      // Analytics: テスト通知エラー
      await AnalyticsService().logError('push_notification_test_error', e.toString());
      
      rethrow;
    }
  }

  /// 通知権限の状態を取得
  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// 通知権限を再リクエスト
  Future<bool> requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}