import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/achievement_card.dart';
import 'notification_settings_screen.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/user_profile.dart';

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
}