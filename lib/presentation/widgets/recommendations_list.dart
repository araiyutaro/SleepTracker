import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/sleep_statistics.dart';

/// 改善提案リストウィジェット
/// ユーザーへの睡眠改善提案を優先度順に表示
class RecommendationsList extends StatelessWidget {
  final List<SleepRecommendation> recommendations;

  const RecommendationsList({
    Key? key,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppTheme.successColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'すべての目標を達成しています！',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: recommendations.asMap().entries.map((entry) {
        final index = entry.key;
        final recommendation = entry.value;
        
        return Column(
          children: [
            _buildRecommendationItem(context, recommendation),
            if (index < recommendations.length - 1)
              const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationItem(BuildContext context, SleepRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getPriorityColor(recommendation.priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getPriorityColor(recommendation.priority).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 優先度アイコン
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _getPriorityColor(recommendation.priority),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getRecommendationIcon(recommendation.type),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          
          // コンテンツ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recommendation.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getPriorityColor(recommendation.priority),
                        ),
                      ),
                    ),
                    _buildPriorityChip(context, recommendation.priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, Priority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getPriorityText(priority),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: _getPriorityColor(priority),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return AppTheme.errorColor;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return AppTheme.primaryColor;
    }
  }

  String _getPriorityText(Priority priority) {
    switch (priority) {
      case Priority.high:
        return '高';
      case Priority.medium:
        return '中';
      case Priority.low:
        return '低';
    }
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.sleepDuration:
        return Icons.schedule;
      case RecommendationType.consistency:
        return Icons.sync;
      case RecommendationType.phoneUsage:
        return Icons.phone_android;
      case RecommendationType.bedtimeOptimal:
        return Icons.bedtime;
      case RecommendationType.qualityImprovement:
        return Icons.star;
    }
  }
}