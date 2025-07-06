import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/sleep_session.dart';
import '../../core/themes/app_theme.dart';

class SleepStagesChart extends StatelessWidget {
  final SleepStageData sleepStages;

  const SleepStagesChart({
    Key? key,
    required this.sleepStages,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '睡眠ステージ分析',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _buildPieChartSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLegend(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStageDetails(context),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return [
      PieChartSectionData(
        color: const Color(0xFF2E5BBA),
        value: sleepStages.deepSleepPercentage,
        title: '${sleepStages.deepSleepPercentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFF6B92F0),
        value: sleepStages.lightSleepPercentage,
        title: '${sleepStages.lightSleepPercentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFFFD93D),
        value: sleepStages.remSleepPercentage,
        title: '${sleepStages.remSleepPercentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      PieChartSectionData(
        color: const Color(0xFFFF6B6B),
        value: sleepStages.awakePercentage,
        title: '${sleepStages.awakePercentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLegendItem(
          '深い睡眠',
          const Color(0xFF2E5BBA),
          '${sleepStages.deepSleepPercentage.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          '浅い睡眠',
          const Color(0xFF6B92F0),
          '${sleepStages.lightSleepPercentage.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'REM睡眠',
          const Color(0xFFFFD93D),
          '${sleepStages.remSleepPercentage.toStringAsFixed(1)}%',
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          '覚醒',
          const Color(0xFFFF6B6B),
          '${sleepStages.awakePercentage.toStringAsFixed(1)}%',
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, String percentage) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Text(
          percentage,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStageDetails(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailCard(
                '総睡眠時間',
                '${sleepStages.totalSleep.toStringAsFixed(1)}%',
                Icons.bedtime,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildDetailCard(
                '体動回数',
                '${sleepStages.movementCount}回',
                Icons.motion_photos_on,
                AppTheme.secondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}