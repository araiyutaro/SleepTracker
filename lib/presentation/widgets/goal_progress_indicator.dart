import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/sleep_statistics.dart';

/// 目標達成度表示ウィジェット
/// ユーザーの睡眠目標に対する達成度を視覚的に表示
class GoalProgressIndicator extends StatelessWidget {
  final GoalProgress goalProgress;

  const GoalProgressIndicator({
    Key? key,
    required this.goalProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (goalProgress.totalDays == 0) {
      return const Text('データが不足しています');
    }

    return Column(
      children: [
        // 全体の達成度
        _buildOverallProgress(context),
        const SizedBox(height: 16),
        
        // 個別目標の達成度
        _buildIndividualGoals(context),
      ],
    );
  }

  Widget _buildOverallProgress(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '全体達成度',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(goalProgress.overallProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: goalProgress.overallProgress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(goalProgress.overallProgress),
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildIndividualGoals(BuildContext context) {
    return Column(
      children: [
        _buildGoalRow(
          context,
          '目標睡眠時間達成',
          goalProgress.sleepDurationGoalAchieved,
          goalProgress.totalDays,
          goalProgress.sleepDurationAchievementRate,
          Icons.schedule,
        ),
        const SizedBox(height: 12),
        _buildGoalRow(
          context,
          '理想就寝時刻達成',
          goalProgress.bedtimeGoalAchieved,
          goalProgress.totalDays,
          goalProgress.bedtimeAchievementRate,
          Icons.bedtime,
        ),
        const SizedBox(height: 12),
        _buildGoalRow(
          context,
          '睡眠品質目標達成',
          goalProgress.qualityGoalAchieved,
          goalProgress.totalDays,
          goalProgress.qualityAchievementRate,
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildGoalRow(
    BuildContext context,
    String label,
    int achieved,
    int total,
    double rate,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: _getProgressColor(rate),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    '$achieved/$total日',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getProgressColor(rate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: rate,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(rate),
                ),
                minHeight: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.8) {
      return AppTheme.successColor;
    } else if (progress >= 0.6) {
      return Colors.orange;
    } else {
      return AppTheme.errorColor;
    }
  }
}