import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_session.dart';
import '../../core/themes/app_theme.dart';
import 'sleep_stages_chart.dart';

class RecentSleepCard extends StatelessWidget {
  final SleepSession session;
  final VoidCallback? onDelete;

  const RecentSleepCard({
    Key? key,
    required this.session,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd (E)', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      child: InkWell(
        onTap: session.sleepStages != null ? () => _showDetailDialog(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, onDelete != null ? 56.0 : 16.0, 16.0),
              child: Row(
                children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getQualityColor(session.qualityScore).withOpacity(0.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.nights_stay,
                    color: _getQualityColor(session.qualityScore),
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(session.startTime),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${timeFormat.format(session.startTime)} - ${session.endTime != null ? timeFormat.format(session.endTime!) : '継続中'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    if (session.sleepStages != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'タップで詳細表示',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDuration(session.calculatedDuration),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (session.qualityScore != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getQualityColor(session.qualityScore),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${session.qualityScore!.toInt()}%',
                          style: TextStyle(
                            color: _getQualityColor(session.qualityScore),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (session.sleepStages != null) ...[
                    const SizedBox(height: 4),
                    Icon(
                      Icons.analytics,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ],
              ),
                ],
              ),
            ),
            if (onDelete != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onPressed: () => _showDeleteConfirmDialog(context),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}時間${minutes}分';
  }

  Color _getQualityColor(double? quality) {
    if (quality == null) return Colors.grey;
    if (quality >= 80) return AppTheme.successColor;
    if (quality >= 60) return Colors.orange;
    return AppTheme.errorColor;
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final dateFormat = DateFormat('yyyy年M月d日', 'ja_JP');
        return Dialog(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateFormat.format(session.startTime),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (session.sleepStages != null)
                  SleepStagesChart(sleepStages: session.sleepStages!),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('睡眠記録を削除'),
        content: const Text('この睡眠記録を削除しますか？\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}