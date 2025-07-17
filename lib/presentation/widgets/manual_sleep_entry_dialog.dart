import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/sleep_session.dart';
import '../../core/themes/app_theme.dart';

class ManualSleepEntryDialog extends StatefulWidget {
  final Function(SleepSession) onSave;

  const ManualSleepEntryDialog({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<ManualSleepEntryDialog> createState() => _ManualSleepEntryDialogState();
}

class _ManualSleepEntryDialogState extends State<ManualSleepEntryDialog> {
  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 8));
  DateTime _endTime = DateTime.now();
  double? _qualityScore;
  int? _wakeQuality;
  final _qualityController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _qualityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Dialog(
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '睡眠記録を追加',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // 説明テキスト
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '過去の睡眠記録を手動で追加できます',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 開始時刻
              _buildTimeSection(
                '開始時刻',
                _startTime,
                (date, time) {
                  final newStartTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  setState(() {
                    _startTime = newStartTime;
                    // 終了時刻が開始時刻より前になる場合は調整
                    if (_endTime.isBefore(_startTime)) {
                      _endTime = _startTime.add(const Duration(hours: 8));
                    }
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 終了時刻
              _buildTimeSection(
                '終了時刻',
                _endTime,
                (date, time) {
                  final newEndTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                  setState(() {
                    _endTime = newEndTime;
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // 睡眠品質
              Text(
                '睡眠品質 (%) - 任意',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qualityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '0-100の数値を入力 (任意)',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null && parsed >= 0 && parsed <= 100) {
                    _qualityScore = parsed;
                  } else if (value.isEmpty) {
                    _qualityScore = null;
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // 目覚めの質
              Text(
                '目覚めの質 (1-5段階) - 任意',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              _buildWakeQualitySelector(),
              
              const SizedBox(height: 24),
              
              // 睡眠時間表示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isValid() 
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValid() ? Icons.access_time : Icons.error_outline,
                      color: _isValid() ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isValid() 
                            ? '睡眠時間: ${_formatDuration(_endTime.difference(_startTime))}'
                            : '終了時刻は開始時刻より後に設定してください',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isValid() ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // ボタン
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isValid() ? _saveEntry : null,
                      child: const Text('追加'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSection(
    String title,
    DateTime currentTime,
    Function(DateTime date, TimeOfDay time) onChanged,
  ) {
    final dateFormat = DateFormat('yyyy年M月d日', 'ja_JP');
    final timeFormat = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(currentTime, onChanged),
                icon: const Icon(Icons.calendar_today),
                label: Text(dateFormat.format(currentTime)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickTime(currentTime, onChanged),
                icon: const Icon(Icons.access_time),
                label: Text(timeFormat.format(currentTime)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(DateTime currentTime, Function(DateTime, TimeOfDay) onChanged) async {
    final date = await showDatePicker(
      context: context,
      initialDate: currentTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    
    if (date != null) {
      onChanged(date, TimeOfDay.fromDateTime(currentTime));
    }
  }

  Future<void> _pickTime(DateTime currentTime, Function(DateTime, TimeOfDay) onChanged) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentTime),
    );
    
    if (time != null) {
      onChanged(
        DateTime(currentTime.year, currentTime.month, currentTime.day),
        time,
      );
    }
  }

  bool _isValid() {
    return _endTime.isAfter(_startTime);
  }

  void _saveEntry() {
    if (!_isValid()) return;

    final session = SleepSession(
      id: _uuid.v4(),
      startTime: _startTime,
      endTime: _endTime,
      duration: _endTime.difference(_startTime),
      qualityScore: _qualityScore,
      wakeQuality: _wakeQuality,
      movements: [],
      createdAt: DateTime.now(),
    );

    widget.onSave(session);
    Navigator.of(context).pop();
  }

  Widget _buildWakeQualitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = _wakeQuality == rating;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _wakeQuality = isSelected ? null : rating;
            });
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? _getRatingColor(rating)
                  : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? _getRatingColor(rating)
                    : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getRatingIcon(rating),
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
                Text(
                  rating.toString(),
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _getRatingColor(int rating) {
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

  IconData _getRatingIcon(int rating) {
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}時間${minutes}分';
  }
}