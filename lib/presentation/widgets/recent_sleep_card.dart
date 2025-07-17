import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_session.dart';
import '../../core/themes/app_theme.dart';
import 'sleep_stages_chart.dart';
import 'edit_sleep_dialog.dart';

class RecentSleepCard extends StatelessWidget {
  final SleepSession session;
  final VoidCallback? onDelete;
  final Function(SleepSession)? onEdit;

  const RecentSleepCard({
    Key? key,
    required this.session,
    this.onDelete,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd (E)', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      child: InkWell(
        onTap: () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.0, 16.0, (onDelete != null || onEdit != null) ? 56.0 : 16.0, 16.0),
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
                    const SizedBox(height: 4),
                    Text(
                      'タップで詳細表示',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                      ),
                    ),
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
                  const SizedBox(height: 4),
                  Icon(
                    Icons.analytics,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
                ],
              ),
            ),
            if (onDelete != null || onEdit != null)
              Positioned(
                top: 8,
                right: 8,
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditDialog(context);
                        break;
                      case 'delete':
                        _showDeleteConfirmDialog(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('編集'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20),
                            SizedBox(width: 8),
                            Text('削除'),
                          ],
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
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        dateFormat.format(session.startTime),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSleepDetails(context),
                        if (session.sleepStages != null) ...[
                          const SizedBox(height: 16),
                          SleepStagesChart(sleepStages: session.sleepStages!),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditSleepDialog(
        session: session,
        onSave: (updatedSession) {
          onEdit?.call(updatedSession);
        },
      ),
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

  Widget _buildSleepDetails(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      '睡眠時間',
                      _formatDuration(session.calculatedDuration),
                      Icons.access_time,
                      AppTheme.primaryColor,
                    ),
                  ),
                  if (session.qualityScore != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDetailItem(
                        '睡眠品質',
                        '${session.qualityScore!.toInt()}%',
                        Icons.star,
                        _getQualityColor(session.qualityScore),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      '就寝時刻',
                      timeFormat.format(session.startTime),
                      Icons.bedtime,
                      AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      '起床時刻',
                      session.endTime != null 
                          ? timeFormat.format(session.endTime!)
                          : '継続中',
                      Icons.wb_sunny,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              if (session.wakeQuality != null) ...[
                const SizedBox(height: 16),
                _buildDetailItem(
                  '目覚めの質',
                  _getWakeQualityText(session.wakeQuality!),
                  _getWakeQualityIcon(session.wakeQuality!),
                  _getWakeQualityColor(session.wakeQuality!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getWakeQualityText(int rating) {
    switch (rating) {
      case 1:
        return 'とても悪い';
      case 2:
        return '悪い';
      case 3:
        return '普通';
      case 4:
        return '良い';
      case 5:
        return 'とても良い';
      default:
        return '不明';
    }
  }

  IconData _getWakeQualityIcon(int rating) {
    switch (rating) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.help_outline;
    }
  }

  Color _getWakeQualityColor(int rating) {
    switch (rating) {
      case 1:
        return AppTheme.errorColor;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return AppTheme.primaryColor;
      case 5:
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }
}