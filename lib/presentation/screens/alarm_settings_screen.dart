import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sleep_provider.dart';
import '../../core/themes/app_theme.dart';
import '../../services/alarm_service.dart';
import '../../services/notification_service.dart';

class AlarmSettingsScreen extends StatefulWidget {
  const AlarmSettingsScreen({Key? key}) : super(key: key);

  @override
  State<AlarmSettingsScreen> createState() => _AlarmSettingsScreenState();
}

class _AlarmSettingsScreenState extends State<AlarmSettingsScreen> {
  TimeOfDay _selectedWakeTime = const TimeOfDay(hour: 7, minute: 0);
  int _smartWindowMinutes = 30;
  bool _isSmartAlarmEnabled = false;
  List<TimeOfDay> _suggestedBedtimes = [];
  late AlarmService _alarmService;

  @override
  void initState() {
    super.initState();
    final sleepProvider = context.read<SleepProvider>();
    final notificationService = NotificationService();
    _alarmService = AlarmService(
      sleepRepository: sleepProvider.sleepRepository,
      notifications: notificationService.flutterLocalNotificationsPlugin,
    );
    _loadSuggestedBedtimes();
  }

  Future<void> _loadSuggestedBedtimes() async {
    final suggestions = await _alarmService.getSuggestedBedtimes(_selectedWakeTime);
    setState(() {
      _suggestedBedtimes = suggestions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スマートアラーム設定'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'スマートアラーム',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '睡眠サイクルを分析して最適なタイミングで起こします',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('スマートアラームを有効にする'),
                      value: _isSmartAlarmEnabled,
                      onChanged: (value) {
                        setState(() {
                          _isSmartAlarmEnabled = value;
                        });
                        if (!value) {
                          _alarmService.cancelAlarm();
                        }
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSmartAlarmEnabled) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '起床時刻設定',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('目標起床時刻'),
                        subtitle: Text(_selectedWakeTime.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectWakeTime,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'スマートアラーム範囲',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '目標時刻の${_smartWindowMinutes}分前から浅い睡眠を検出',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Slider(
                        value: _smartWindowMinutes.toDouble(),
                        min: 15,
                        max: 60,
                        divisions: 9,
                        label: '${_smartWindowMinutes}分',
                        onChanged: (value) {
                          setState(() {
                            _smartWindowMinutes = value.round();
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '推奨就寝時刻',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '睡眠サイクル（90分）を考慮した最適な就寝時刻',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      ..._suggestedBedtimes.asMap().entries.map((entry) {
                        final index = entry.key;
                        final bedtime = entry.value;
                        final cycles = 6 - index;
                        final sleepHours = (cycles * 1.5).toStringAsFixed(1);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            title: Text(bedtime.format(context)),
                            subtitle: Text('${sleepHours}時間睡眠 (${cycles}サイクル)'),
                            trailing: Icon(
                              Icons.nights_stay,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _setAlarm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'アラームを設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelAlarm,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'アラームをキャンセル',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectWakeTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedWakeTime,
    );
    if (picked != null && picked != _selectedWakeTime) {
      setState(() {
        _selectedWakeTime = picked;
      });
      await _loadSuggestedBedtimes();
    }
  }

  Future<void> _setAlarm() async {
    try {
      await _alarmService.scheduleSmartAlarm(
        targetWakeTime: _selectedWakeTime,
        windowMinutes: _smartWindowMinutes,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'スマートアラームを${_selectedWakeTime.format(context)}に設定しました',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アラーム設定に失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelAlarm() async {
    try {
      await _alarmService.cancelAlarm();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('アラームをキャンセルしました'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('アラームキャンセルに失敗しました: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _alarmService.dispose();
    super.dispose();
  }
}