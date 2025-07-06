import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/themes/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettings _settings;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    final userProvider = context.read<UserProvider>();
    _settings = userProvider.userProfile?.notificationSettings ?? NotificationSettings();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final userProvider = context.read<UserProvider>();
    _permissionsGranted = await userProvider.requestNotificationPermissions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('保存'),
          ),
        ],
      ),
      body: !_permissionsGranted
          ? _buildPermissionRequest()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('就寝リマインダー'),
                  _buildBedtimeReminderSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('起床アラーム'),
                  _buildWakeUpAlarmSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('その他の通知'),
                  _buildOtherNotificationsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '通知の許可が必要です',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '睡眠リマインダーやアラーム機能を使用するために、通知の許可が必要です。',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkPermissions,
              child: const Text('許可を確認'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildBedtimeReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('就寝リマインダー'),
              subtitle: const Text('設定した就寝時刻の前にお知らせします'),
              value: _settings.bedtimeReminderEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(bedtimeReminderEnabled: value);
                });
              },
            ),
            if (_settings.bedtimeReminderEnabled) ...[
              const Divider(),
              ListTile(
                title: const Text('リマインダー時間'),
                subtitle: Text('${_settings.bedtimeReminderMinutes}分前'),
                trailing: SizedBox(
                  width: 100,
                  child: DropdownButton<int>(
                    value: _settings.bedtimeReminderMinutes,
                    items: [15, 30, 45, 60].map((minutes) {
                      return DropdownMenuItem(
                        value: minutes,
                        child: Text('${minutes}分前'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _settings = _settings.copyWith(bedtimeReminderMinutes: value);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWakeUpAlarmSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SwitchListTile(
          title: const Text('起床アラーム'),
          subtitle: const Text('設定した起床時刻にアラームを鳴らします'),
          value: _settings.wakeUpAlarmEnabled,
          onChanged: (value) {
            setState(() {
              _settings = _settings.copyWith(wakeUpAlarmEnabled: value);
            });
          },
        ),
      ),
    );
  }

  Widget _buildOtherNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('睡眠品質通知'),
              subtitle: const Text('睡眠記録終了時に品質をお知らせします'),
              value: _settings.sleepQualityNotificationEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(sleepQualityNotificationEnabled: value);
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('週間レポート'),
              subtitle: const Text('毎週日曜日に睡眠データをお知らせします'),
              value: _settings.weeklyReportEnabled,
              onChanged: (value) {
                setState(() {
                  _settings = _settings.copyWith(weeklyReportEnabled: value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    final userProvider = context.read<UserProvider>();
    userProvider.updateNotificationSettings(_settings);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通知設定を保存しました'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    
    Navigator.of(context).pop();
  }
}