import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../widgets/sleep_button.dart';
import '../widgets/sleep_timer_display.dart';
import '../widgets/recent_sleep_card.dart';
import '../../core/themes/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<SleepProvider>(
          builder: (context, sleepProvider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getSubtitle(sleepProvider.isTracking),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (sleepProvider.isTracking) ...[
                    SleepTimerDisplay(
                      duration: sleepProvider.currentDuration,
                    ),
                    const SizedBox(height: 40),
                  ],
                  SleepButton(
                    isTracking: sleepProvider.isTracking,
                    isLoading: sleepProvider.state == SleepTrackingState.loading,
                    onPressed: () {
                      if (sleepProvider.isTracking) {
                        sleepProvider.stopTracking();
                      } else {
                        sleepProvider.startTracking();
                      }
                    },
                  ),
                  if (sleepProvider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        sleepProvider.errorMessage!,
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  if (sleepProvider.recentSessions.isNotEmpty) ...[
                    Text(
                      '最近の睡眠記録',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    ...sleepProvider.recentSessions.take(3).map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RecentSleepCard(session: session),
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'おはようございます';
    } else if (hour < 18) {
      return 'こんにちは';
    } else {
      return 'こんばんは';
    }
  }

  String _getSubtitle(bool isTracking) {
    if (isTracking) {
      return 'おやすみなさい...';
    } else {
      final hour = DateTime.now().hour;
      if (hour >= 22 || hour < 6) {
        return 'そろそろ寝る時間ですね';
      } else {
        return '今日も良い一日を';
      }
    }
  }
}