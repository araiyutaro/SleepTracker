import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme.dart';
import '../providers/user_provider.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';
import '../../services/firebase_service.dart';
import '../../config/flavor_config.dart';

class PushNotificationSettingsScreen extends StatefulWidget {
  const PushNotificationSettingsScreen({super.key});

  @override
  State<PushNotificationSettingsScreen> createState() => _PushNotificationSettingsScreenState();
}

class _PushNotificationSettingsScreenState extends State<PushNotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;
  bool _isPushEnabled = false;
  String? _fcmToken;
  
  // トピック購読状態
  bool _sleepRemindersEnabled = true;
  bool _sleepTipsEnabled = true;
  bool _weeklyReportsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationStatus();
    
    // Analytics: 設定画面表示
    AnalyticsService().logScreenView('push_notification_settings');
  }

  Future<void> _loadNotificationStatus() async {
    try {
      _isPushEnabled = await _notificationService.isPushNotificationEnabled();
      _fcmToken = _notificationService.fcmToken;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load notification status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebaseが初期化されていない場合の表示
    if (!FirebaseService.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('プッシュ通知設定'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'プッシュ通知機能は利用できません',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Firebaseの設定が必要です。\n開発者にお問い合わせください。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'ローカル通知は引き続き利用可能です',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プッシュ通知設定'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPermissionStatusCard(),
                  const SizedBox(height: 20),
                  _buildTopicSubscriptionSection(),
                  const SizedBox(height: 20),
                  _buildTokenInfoSection(),
                  const SizedBox(height: 20),
                  _buildTestSection(),
                  const SizedBox(height: 20),
                  _buildTroubleshootingSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionStatusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isPushEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: _isPushEnabled ? AppTheme.successColor : AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'プッシュ通知の状態',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isPushEnabled 
                    ? AppTheme.successColor.withOpacity(0.1)
                    : AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isPushEnabled ? Icons.check_circle : Icons.error,
                    color: _isPushEnabled ? AppTheme.successColor : AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isPushEnabled 
                          ? 'プッシュ通知が有効です'
                          : 'プッシュ通知が無効です',
                      style: TextStyle(
                        color: _isPushEnabled ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_isPushEnabled) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermissions,
                  icon: const Icon(Icons.settings),
                  label: const Text('通知許可を設定'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSubscriptionSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '通知の種類',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '受信したい通知の種類を選択してください',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTopicSwitch(
              title: '睡眠リマインダー',
              subtitle: '就寝時刻やメンテナンス情報',
              value: _sleepRemindersEnabled,
              onChanged: _isPushEnabled ? (value) {
                setState(() => _sleepRemindersEnabled = value);
                _updateTopicSubscription('sleep_reminders', value);
              } : null,
            ),
            
            _buildTopicSwitch(
              title: '睡眠のコツ',
              subtitle: 'より良い睡眠のためのアドバイス',
              value: _sleepTipsEnabled,
              onChanged: _isPushEnabled ? (value) {
                setState(() => _sleepTipsEnabled = value);
                _updateTopicSubscription('sleep_tips', value);
              } : null,
            ),
            
            _buildTopicSwitch(
              title: '週間レポート',
              subtitle: '週1回の睡眠分析レポート',
              value: _weeklyReportsEnabled,
              onChanged: _isPushEnabled ? (value) {
                setState(() => _weeklyReportsEnabled = value);
                _updateTopicSubscription('weekly_reports', value);
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildTokenInfoSection() {
    if (!_isPushEnabled || _fcmToken == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.key, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'デバイストークン情報',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FCM Token (開発者向け):',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_fcmToken!.substring(0, 20)}...',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'トークン長: ${_fcmToken!.length}文字',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection() {
    // dev版のみテスト機能を表示
    if (!FlavorConfig.isDev) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bug_report, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'テスト機能',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'プッシュ通知が正常に動作するかテストできます。',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isPushEnabled ? _sendTestNotification : null,
                icon: const Icon(Icons.send),
                label: const Text('テスト通知を送信'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.help_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'トラブルシューティング',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'プッシュ通知が届かない場合:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildTroubleshootingItem('デバイスの設定で通知が許可されているか確認'),
            _buildTroubleshootingItem('アプリがバックグラウンドで実行されているか確認'),
            _buildTroubleshootingItem('ネットワーク接続が正常か確認'),
            _buildTroubleshootingItem('アプリを再起動してみる'),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final userProvider = context.read<UserProvider>();
      final granted = await userProvider.requestNotificationPermissions();
      
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プッシュ通知の許可が設定されました'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 状態を再読み込み
        await _loadNotificationStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('プッシュ通知の許可が拒否されました'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Analytics: 許可リクエスト結果
      await AnalyticsService().logCustomEvent('push_notification_permission_requested', parameters: {
        'granted': granted,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateTopicSubscription(String topic, bool subscribe) async {
    try {
      if (subscribe) {
        await _notificationService.subscribeToTopic(topic);
      } else {
        await _notificationService.unsubscribeFromTopic(topic);
      }
      
      // Analytics: トピック購読変更
      await AnalyticsService().logCustomEvent('push_notification_topic_changed', parameters: {
        'topic': topic,
        'subscribed': subscribe,
      });
    } catch (e) {
      debugPrint('Failed to update topic subscription: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('設定の更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      await _notificationService.sendTestPushNotification();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('テスト通知を送信しました'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Analytics: テスト通知送信
      await AnalyticsService().logCustomEvent('push_notification_test_sent');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('テスト通知の送信に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}