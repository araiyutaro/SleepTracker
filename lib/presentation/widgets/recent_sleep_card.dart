import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/sleep_session.dart';
import '../../core/themes/app_theme.dart';

class RecentSleepCard extends StatelessWidget {
  final SleepSession session;

  const RecentSleepCard({
    Key? key,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MM/dd (E)', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              ],
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
}