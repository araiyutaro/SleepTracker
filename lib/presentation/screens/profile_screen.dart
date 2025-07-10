import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/sleep_provider.dart';
import '../widgets/achievement_card.dart';
import 'notification_settings_screen.dart';
import 'alarm_settings_screen.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../services/export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _showSettingsDialog();
                  break;
                case 'notifications':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  );
                  break;
                case 'export':
                  _showExportDialog();
                  break;
                case 'alarm':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AlarmSettingsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('基本設定'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'notifications',
                child: ListTile(
                  leading: Icon(Icons.notifications),
                  title: Text('通知設定'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('データエクスポート'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'alarm',
                child: ListTile(
                  leading: Icon(Icons.alarm),
                  title: Text('スマートアラーム'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final profile = userProvider.userProfile;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileCard(profile),
                const SizedBox(height: 16),
                _buildPointsCard(profile),
                const SizedBox(height: 16),
                _buildHealthIntegrationCard(),
                const SizedBox(height: 24),
                _buildAchievementsSection(profile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(UserProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'スリープマスター',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'レベル ${_calculateLevel(profile.points)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsCard(UserProfile profile) {
    final currentLevel = _calculateLevel(profile.points);
    final currentLevelPoints = _getPointsForLevel(currentLevel);
    final nextLevelPoints = _getPointsForLevel(currentLevel + 1);
    final progress = (profile.points - currentLevelPoints) /
        (nextLevelPoints - currentLevelPoints);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ポイント',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${profile.points} pt',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'レベル $currentLevel',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      'レベル ${currentLevel + 1}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  '次のレベルまで ${nextLevelPoints - profile.points} ポイント',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(UserProfile profile) {
    final achievements = _getDefaultAchievements();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'アチーブメント',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final isUnlocked = profile.achievements.any((a) => a.id == achievement.id && a.isUnlocked);
            return AchievementCard(
              achievement: achievement,
              isUnlocked: isUnlocked,
            );
          },
        ),
      ],
    );
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 'first_sleep',
        name: '初めての記録',
        description: '初めて睡眠を記録',
        iconPath: 'assets/achievements/first_sleep.png',
        points: 50,
      ),
      Achievement(
        id: 'week_streak',
        name: '週間マスター',
        description: '7日連続で記録',
        iconPath: 'assets/achievements/week_streak.png',
        points: 100,
      ),
      Achievement(
        id: 'early_bird',
        name: '早起き鳥',
        description: '5回6時前に起床',
        iconPath: 'assets/achievements/early_bird.png',
        points: 75,
      ),
      Achievement(
        id: 'perfect_sleep',
        name: '完璧な睡眠',
        description: '8時間睡眠を達成',
        iconPath: 'assets/achievements/perfect_sleep.png',
        points: 80,
      ),
      Achievement(
        id: 'month_streak',
        name: '月間マスター',
        description: '30日連続で記録',
        iconPath: 'assets/achievements/month_streak.png',
        points: 200,
      ),
      Achievement(
        id: 'sleep_quality',
        name: '高品質睡眠',
        description: '品質90%以上を5回達成',
        iconPath: 'assets/achievements/sleep_quality.png',
        points: 150,
      ),
    ];
  }

  int _calculateLevel(int points) {
    return (points ~/ 500) + 1;
  }

  int _getPointsForLevel(int level) {
    return (level - 1) * 500;
  }

  Widget _buildHealthIntegrationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.health_and_safety, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'ヘルスデータ連携',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apple HealthKit / Google Fitと連携して、より詳細な健康データを分析できます。\n\n※ この機能はオプションです。連携しなくてもアプリを利用できます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Consumer<SleepProvider>(
              builder: (context, sleepProvider, child) {
                return FutureBuilder<bool>(
                  future: _checkHealthPermissions(sleepProvider),
                  builder: (context, snapshot) {
                    final hasPermissions = snapshot.data ?? false;
                    final isLoading = snapshot.connectionState == ConnectionState.waiting;
                    
                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    return Column(
                      children: [
                        if (hasPermissions) ...
                          _buildPermissionGrantedUI(sleepProvider)
                        else ...
                          _buildPermissionNotGrantedUI(sleepProvider),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _checkHealthPermissions(SleepProvider sleepProvider) async {
    try {
      final healthService = sleepProvider.healthService;
      if (!healthService.isInitialized) {
        await healthService.initialize();
      }
      return await healthService.hasPermissions();
    } catch (e) {
      debugPrint('Error checking health permissions: $e');
      return false;
    }
  }
  
  List<Widget> _buildPermissionGrantedUI(SleepProvider sleepProvider) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ヘルスデータ連携が有効です',
                style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showHealthSummary(sleepProvider),
          icon: const Icon(Icons.analytics),
          label: const Text('ヘルスデータを表示'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ];
  }
  
  List<Widget> _buildPermissionNotGrantedUI(SleepProvider sleepProvider) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ヘルスデータ連携は未設定です',
                    style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '連携しなくてもアプリの機能は利用できます。',
              style: TextStyle(color: Colors.orange[600], fontSize: 12),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _requestHealthPermissions(sleepProvider),
          icon: const Icon(Icons.security),
          label: const Text('ヘルスデータ連携を設定する'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryColor,
            side: BorderSide(color: AppTheme.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    ];
  }
  
  Future<void> _requestHealthPermissions(SleepProvider sleepProvider) async {
    try {
      debugPrint('ProfileScreen: Starting health permissions request...');
      
      bool granted = await sleepProvider.requestHealthPermissions();
      
      debugPrint('ProfileScreen: Health permissions result: $granted');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(granted 
              ? 'ヘルスデータ連携が有効になりました。自動でデータが同期されます。'
              : 'ヘルスデータ連携は設定されませんでした。アプリは通常通りご利用いただけます。'),
            backgroundColor: granted ? Colors.green : Colors.orange,
            duration: Duration(seconds: granted ? 4 : 6),
          ),
        );
        
        // 権限が拒否された場合、詳細情報を表示
        if (!granted) {
          _showPermissionDeniedDialog();
        } else {
          // 権限が許可された場合、UIを更新
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('ProfileScreen: Error requesting health permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しましたが、アプリは継続してご利用いただけます。'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルスデータ連携について'),
        content: const Text(
          'ヘルスデータ連携はオプション機能です。\n\n'
          'アプリは連携なしでも睡眠記録、分析、通知などすべての機能をご利用いただけます。\n\n'
          '連携を希望する場合は、以下の手順で設定できます：\n\n'
          'iOS: 設定 > プライバシーとセキュリティ > ヘルスケア > Sleep\n'
          'Android: 設定 > アプリと通知 > Sleep > 権限'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('理解しました'),
          ),
        ],
      ),
    );
  }

  Future<void> _showHealthSummary(SleepProvider sleepProvider) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルスデータ取得中...'),
        content: const CircularProgressIndicator(),
      ),
    );

    try {
      Map<String, dynamic> healthData = await sleepProvider.getHealthSummary();
      
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog を閉じる
        
        _showHealthDataDialog(healthData);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Loading dialog を閉じる
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ヘルスデータの取得に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showHealthDataDialog(Map<String, dynamic> healthData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ヘルスデータサマリー'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHealthDataItem('睡眠データ', healthData['sleepData']?.length ?? 0),
              _buildHealthDataItem('心拍数データ', healthData['heartRateData']?.length ?? 0),
              _buildHealthDataItem('歩数データ', healthData['stepsData']?.length ?? 0),
              _buildHealthDataItem('カロリーデータ', healthData['caloriesData']?.length ?? 0),
              const SizedBox(height: 16),
              Text(
                '最終更新: ${DateFormat('MM/dd HH:mm').format(healthData['lastUpdated'] ?? DateTime.now())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthDataItem(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '$count件',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    final userProvider = context.read<UserProvider>();
    final profile = userProvider.userProfile!;
    
    TimeOfDay selectedBedtime = profile.targetBedtime;
    TimeOfDay selectedWakeTime = profile.targetWakeTime;
    double selectedSleepHours = profile.targetSleepHours;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('目標設定'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('目標睡眠時間'),
                    subtitle: Text('${selectedSleepHours.toStringAsFixed(1)}時間'),
                    trailing: SizedBox(
                      width: 150,
                      child: Slider(
                        value: selectedSleepHours,
                        min: 4,
                        max: 12,
                        divisions: 16,
                        onChanged: (value) {
                          setState(() {
                            selectedSleepHours = value;
                          });
                        },
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('目標就寝時刻'),
                    subtitle: Text(selectedBedtime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedBedtime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedBedtime = time;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('目標起床時刻'),
                    subtitle: Text(selectedWakeTime.format(context)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: selectedWakeTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedWakeTime = time;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    userProvider.updateSettings(
                      targetSleepHours: selectedSleepHours,
                      targetBedtime: selectedBedtime,
                      targetWakeTime: selectedWakeTime,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExportDialog() {
    final sleepProvider = context.read<SleepProvider>();
    final exportService = ExportService(sleepRepository: sleepProvider.sleepRepository);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データエクスポート'),
        content: const Text('睡眠データをエクスポートする形式を選択してください'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData(exportService, 'csv');
            },
            child: const Text('CSV'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData(exportService, 'json');
            },
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _exportData(exportService, 'text');
            },
            child: const Text('テキスト'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(ExportService exportService, String format) async {
    try {
      final now = DateTime.now();
      final dateFormat = DateFormat('yyyyMMdd_HHmmss');
      String content;
      String fileName;

      switch (format) {
        case 'csv':
          content = await exportService.exportToCSV();
          fileName = 'sleep_data_${dateFormat.format(now)}.csv';
          break;
        case 'json':
          content = await exportService.exportToJSON();
          fileName = 'sleep_data_${dateFormat.format(now)}.json';
          break;
        case 'text':
          content = await exportService.exportToText();
          fileName = 'sleep_data_${dateFormat.format(now)}.txt';
          break;
        default:
          throw Exception('Unsupported format: $format');
      }

      final file = await exportService.saveToFile(content, fileName);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('データをエクスポートしました: ${file.path}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エクスポートに失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}