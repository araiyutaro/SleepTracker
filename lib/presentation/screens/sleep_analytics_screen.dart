import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/themes/app_theme.dart';
import '../../domain/entities/sleep_statistics.dart';
import '../../services/personal_analytics_service.dart';
import '../widgets/analytics_card.dart';
import '../widgets/sleep_trend_chart.dart';
import '../widgets/recommendations_list.dart';
import '../widgets/goal_progress_indicator.dart';

/// 睡眠分析画面
/// 個人の睡眠データを分析し、統計情報と改善提案を表示
class SleepAnalyticsScreen extends StatefulWidget {
  const SleepAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<SleepAnalyticsScreen> createState() => _SleepAnalyticsScreenState();
}

class _SleepAnalyticsScreenState extends State<SleepAnalyticsScreen> {
  final PersonalAnalyticsService _analyticsService = PersonalAnalyticsService();
  
  SleepStatistics? _statistics;
  List<WeeklyTrend>? _weeklyTrends;
  PatternAnalysis? _patternAnalysis;
  List<SleepRecommendation>? _recommendations;
  GoalProgress? _goalProgress;
  
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      const userId = 'default_user'; // 実際のユーザーIDに置き換え
      
      final results = await Future.wait([
        _analyticsService.calculateBasicStatistics(userId),
        _analyticsService.calculateWeeklyTrends(userId, 4),
        _analyticsService.analyzeWeekdayWeekendPatterns(userId),
        _analyticsService.generateRecommendations(userId),
        _analyticsService.calculateGoalProgress(userId),
      ]);

      setState(() {
        _statistics = results[0] as SleepStatistics;
        _weeklyTrends = results[1] as List<WeeklyTrend>;
        _patternAnalysis = results[2] as PatternAnalysis;
        _recommendations = results[3] as List<SleepRecommendation>;
        _goalProgress = results[4] as GoalProgress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'データの読み込みに失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('睡眠分析'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildAnalyticsView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnalyticsData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    if (_statistics == null) return const SizedBox();

    return RefreshIndicator(
      onRefresh: _loadAnalyticsData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今週のサマリー
            _buildWeeklySummaryCard(),
            const SizedBox(height: 16),
            
            // 目標達成度
            if (_goalProgress != null)
              _buildGoalProgressCard(),
            const SizedBox(height: 16),
            
            // 睡眠時間推移
            _buildTrendCard(),
            const SizedBox(height: 16),
            
            // 平日/休日比較
            if (_patternAnalysis != null)
              _buildPatternAnalysisCard(),
            const SizedBox(height: 16),
            
            // 改善提案
            if (_recommendations != null && _recommendations!.isNotEmpty)
              _buildRecommendationsCard(),
            const SizedBox(height: 16),
            
            // 詳細統計
            _buildDetailedStatsCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return AnalyticsCard(
      title: '今週のサマリー',
      icon: Icons.analytics,
      child: Column(
        children: [
          _buildSummaryRow('平均睡眠時間', _statistics!.averageSleepDurationFormatted),
          _buildSummaryRow('平均品質', _statistics!.averageSleepQualityFormatted),
          _buildSummaryRow('規則性スコア', _statistics!.consistencyScoreFormatted),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    return AnalyticsCard(
      title: '目標達成度',
      icon: Icons.track_changes,
      child: GoalProgressIndicator(
        goalProgress: _goalProgress!,
      ),
    );
  }

  Widget _buildTrendCard() {
    return AnalyticsCard(
      title: '睡眠時間推移（過去4週間）',
      icon: Icons.trending_up,
      child: _weeklyTrends != null && _weeklyTrends!.isNotEmpty
          ? SleepTrendChart(weeklyTrends: _weeklyTrends!)
          : const Text('データが不足しています'),
    );
  }

  Widget _buildPatternAnalysisCard() {
    return AnalyticsCard(
      title: '平日 vs 休日比較',
      icon: Icons.compare_arrows,
      child: Column(
        children: [
          _buildPatternRow(
            '平日平均',
            '${_patternAnalysis!.weekdayAverageDuration.inHours}時間${_patternAnalysis!.weekdayAverageDuration.inMinutes.remainder(60)}分',
            '品質: ${_patternAnalysis!.weekdayAverageQuality.toInt()}%',
          ),
          const SizedBox(height: 8),
          _buildPatternRow(
            '休日平均',
            '${_patternAnalysis!.weekendAverageDuration.inHours}時間${_patternAnalysis!.weekendAverageDuration.inMinutes.remainder(60)}分',
            '品質: ${_patternAnalysis!.weekendAverageQuality.toInt()}%',
          ),
          const SizedBox(height: 8),
          _buildPatternRow(
            '社会的ジェットラグ',
            _patternAnalysis!.socialJetlagFormatted,
            '',
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return AnalyticsCard(
      title: '改善提案',
      icon: Icons.lightbulb_outline,
      child: RecommendationsList(recommendations: _recommendations!),
    );
  }

  Widget _buildDetailedStatsCard() {
    return AnalyticsCard(
      title: '詳細統計',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          _buildSummaryRow('記録日数', '${_statistics!.totalRecords}日'),
          if (_statistics!.shortestSleep != null)
            _buildSummaryRow('最短睡眠時間', '${_statistics!.shortestSleep!.inHours}時間${_statistics!.shortestSleep!.inMinutes.remainder(60)}分'),
          if (_statistics!.longestSleep != null)
            _buildSummaryRow('最長睡眠時間', '${_statistics!.longestSleep!.inHours}時間${_statistics!.longestSleep!.inMinutes.remainder(60)}分'),
          if (_statistics!.highestQuality != null)
            _buildSummaryRow('最高品質', '${_statistics!.highestQuality!.toInt()}%'),
          if (_statistics!.lowestQuality != null)
            _buildSummaryRow('最低品質', '${_statistics!.lowestQuality!.toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRow(String label, String value, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
              ),
          ],
        ),
      ],
    );
  }
}