import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';
import '../../core/themes/app_theme.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;

  const AchievementCard({
    Key? key,
    required this.achievement,
    required this.isUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isUnlocked ? 2 : 0,
      color: isUnlocked
          ? Theme.of(context).cardTheme.color
          : Colors.grey[200],
      child: InkWell(
        onTap: () => _showAchievementDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock,
                size: 36,
                color: isUnlocked
                    ? AppTheme.accentColor
                    : Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isUnlocked
                      ? Theme.of(context).textTheme.bodyLarge?.color
                      : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked) ...[
                const SizedBox(height: 4),
                Text(
                  '+${achievement.points}pt',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isUnlocked ? Icons.emoji_events : Icons.lock,
                color: isUnlocked
                    ? AppTheme.accentColor
                    : Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  achievement.name,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (isUnlocked) ...[
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '獲得済み',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '獲得ポイント: ${achievement.points}pt',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '条件を達成すると解除されます',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}