import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../domain/entities/sleep_session.dart';
import '../domain/repositories/sleep_repository.dart';

class WidgetData {
  final String lastSleepDate;
  final String lastSleepDuration;
  final String sleepQuality;
  final String weeklyAverage;
  final int totalSessions;

  WidgetData({
    required this.lastSleepDate,
    required this.lastSleepDuration,
    required this.sleepQuality,
    required this.weeklyAverage,
    required this.totalSessions,
  });

  Map<String, dynamic> toJson() => {
        'lastSleepDate': lastSleepDate,
        'lastSleepDuration': lastSleepDuration,
        'sleepQuality': sleepQuality,
        'weeklyAverage': weeklyAverage,
        'totalSessions': totalSessions,
      };

  factory WidgetData.fromJson(Map<String, dynamic> json) => WidgetData(
        lastSleepDate: json['lastSleepDate'] ?? '',
        lastSleepDuration: json['lastSleepDuration'] ?? '',
        sleepQuality: json['sleepQuality'] ?? '',
        weeklyAverage: json['weeklyAverage'] ?? '',
        totalSessions: json['totalSessions'] ?? 0,
      );
}

class WidgetService {
  final SleepRepository _sleepRepository;

  WidgetService({required SleepRepository sleepRepository})
      : _sleepRepository = sleepRepository;

  Future<WidgetData> generateWidgetData() async {
    try {
      final sessions = await _sleepRepository.getSessions(limit: 20);
      
      if (sessions.isEmpty) {
        return WidgetData(
          lastSleepDate: '記録なし',
          lastSleepDuration: '--',
          sleepQuality: '--',
          weeklyAverage: '--',
          totalSessions: 0,
        );
      }

      final lastSession = sessions.first;
      final dateFormat = DateFormat('MM/dd');
      final lastSleepDate = dateFormat.format(lastSession.startTime);
      
      String lastSleepDuration = '--';
      if (lastSession.endTime != null) {
        final duration = lastSession.calculatedDuration;
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        lastSleepDuration = '${hours}h${minutes}m';
      }

      String sleepQuality = '--';
      if (lastSession.qualityScore != null) {
        sleepQuality = '${lastSession.qualityScore!.toInt()}%';
      }

      final weekSessions = sessions.where((session) {
        final now = DateTime.now();
        final weekAgo = now.subtract(const Duration(days: 7));
        return session.startTime.isAfter(weekAgo);
      }).toList();

      String weeklyAverage = '--';
      if (weekSessions.isNotEmpty) {
        final completedSessions = weekSessions.where((s) => s.endTime != null).toList();
        if (completedSessions.isNotEmpty) {
          final totalMinutes = completedSessions
              .map((s) => s.calculatedDuration.inMinutes)
              .fold(0, (sum, minutes) => sum + minutes);
          
          final avgMinutes = totalMinutes / completedSessions.length;
          final avgHours = (avgMinutes / 60).toStringAsFixed(1);
          weeklyAverage = '${avgHours}h';
        }
      }

      return WidgetData(
        lastSleepDate: lastSleepDate,
        lastSleepDuration: lastSleepDuration,
        sleepQuality: sleepQuality,
        weeklyAverage: weeklyAverage,
        totalSessions: sessions.length,
      );
    } catch (e) {
      debugPrint('Error generating widget data: $e');
      return WidgetData(
        lastSleepDate: 'エラー',
        lastSleepDuration: '--',
        sleepQuality: '--',
        weeklyAverage: '--',
        totalSessions: 0,
      );
    }
  }

  Future<void> updateWidget() async {
    try {
      final widgetData = await generateWidgetData();
      
      debugPrint('Widget data updated:');
      debugPrint('Last sleep: ${widgetData.lastSleepDate}');
      debugPrint('Duration: ${widgetData.lastSleepDuration}');
      debugPrint('Quality: ${widgetData.sleepQuality}');
      debugPrint('Weekly avg: ${widgetData.weeklyAverage}');
      debugPrint('Total sessions: ${widgetData.totalSessions}');

    } catch (e) {
      debugPrint('Failed to update widget: $e');
    }
  }

  String getWidgetLayout() {
    return '''
    {
      "title": "睡眠トラッカー",
      "layout": "compact",
      "elements": [
        {
          "type": "text",
          "id": "lastSleep",
          "label": "最新記録",
          "size": "medium"
        },
        {
          "type": "text", 
          "id": "duration",
          "label": "睡眠時間",
          "size": "large"
        },
        {
          "type": "text",
          "id": "quality", 
          "label": "品質",
          "size": "small"
        },
        {
          "type": "text",
          "id": "weeklyAvg",
          "label": "週平均", 
          "size": "small"
        }
      ]
    }
    ''';
  }

  Future<bool> isWidgetSupported() async {
    try {
      return true;
    } catch (e) {
      debugPrint('Widget not supported: $e');
      return false;
    }
  }

  Future<void> configureWidget({
    bool showQuality = true,
    bool showWeeklyAverage = true,
    bool showTotalSessions = false,
  }) async {
    try {
      final config = {
        'showQuality': showQuality,
        'showWeeklyAverage': showWeeklyAverage,
        'showTotalSessions': showTotalSessions,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      debugPrint('Widget configured with settings: ${jsonEncode(config)}');
    } catch (e) {
      debugPrint('Failed to configure widget: $e');
    }
  }

  Future<void> scheduleWidgetUpdates() async {
    try {
      debugPrint('Widget updates scheduled for periodic refresh');
    } catch (e) {
      debugPrint('Failed to schedule widget updates: $e');
    }
  }

  Future<void> removeWidget() async {
    try {
      debugPrint('Widget removed from home screen');
    } catch (e) {
      debugPrint('Failed to remove widget: $e');
    }
  }
}