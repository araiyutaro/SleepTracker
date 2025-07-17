import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/sleep_statistics.dart';

/// 睡眠トレンドチャートウィジェット
/// 週間の睡眠時間と品質の推移を棒グラフで表示
class SleepTrendChart extends StatelessWidget {
  final List<WeeklyTrend> weeklyTrends;

  const SleepTrendChart({
    Key? key,
    required this.weeklyTrends,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weeklyTrends.isEmpty) {
      return const Center(
        child: Text('データがありません'),
      );
    }

    return Column(
      children: [
        // グラフエリア
        SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _buildBars(context),
          ),
        ),
        const SizedBox(height: 16),
        
        // 凡例
        _buildLegend(context),
      ],
    );
  }

  List<Widget> _buildBars(BuildContext context) {
    if (weeklyTrends.isEmpty) return [];

    final maxDuration = weeklyTrends
        .map((trend) => trend.averageDuration.inMinutes)
        .reduce((a, b) => a > b ? a : b);

    return weeklyTrends.asMap().entries.map((entry) {
      final index = entry.key;
      final trend = entry.value;
      
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            left: index == 0 ? 0 : 4,
            right: index == weeklyTrends.length - 1 ? 0 : 4,
          ),
          child: _buildWeekBar(context, trend, maxDuration),
        ),
      );
    }).toList();
  }

  Widget _buildWeekBar(BuildContext context, WeeklyTrend trend, int maxDuration) {
    final chartHeight = 120.0; // チャートの高さを調整
    final durationHeight = maxDuration > 0
        ? (trend.averageDuration.inMinutes / maxDuration) * chartHeight
        : 0.0;
    
    final qualityHeight = (trend.averageQuality / 100) * chartHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // データ表示
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${trend.averageDuration.inHours}h${trend.averageDuration.inMinutes.remainder(60)}m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                '${trend.averageQuality.toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        // バーチャート
        SizedBox(
          width: double.infinity,
          height: chartHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 睡眠時間バー（背景）
              Container(
                width: double.infinity,
                height: durationHeight,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              
              // 睡眠品質バー（前景）
              Container(
                width: double.infinity,
                height: qualityHeight,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        
        // 週ラベル
        Text(
          _formatWeekLabel(trend.weekStart),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context,
          AppTheme.primaryColor,
          '睡眠品質（％）',
        ),
        const SizedBox(width: 24),
        _buildLegendItem(
          context,
          AppTheme.primaryColor.withOpacity(0.3),
          '睡眠時間（時間）',
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _formatWeekLabel(DateTime weekStart) {
    final month = weekStart.month;
    final day = weekStart.day;
    return '$month/$day';
  }
}