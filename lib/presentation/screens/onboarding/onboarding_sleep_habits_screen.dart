import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../widgets/onboarding_progress_bar.dart';
import 'onboarding_phone_usage_screen.dart';

class OnboardingSleepHabitsScreen extends StatefulWidget {
  final String? nickname;
  final String ageGroup;
  final String gender;
  final String? occupation;

  const OnboardingSleepHabitsScreen({
    Key? key,
    this.nickname,
    required this.ageGroup,
    required this.gender,
    this.occupation,
  }) : super(key: key);

  @override
  State<OnboardingSleepHabitsScreen> createState() => _OnboardingSleepHabitsScreenState();
}

class _OnboardingSleepHabitsScreenState extends State<OnboardingSleepHabitsScreen> {
  TimeOfDay? _weekdayBedtime;
  TimeOfDay? _weekdayWakeTime;
  TimeOfDay? _weekendBedtime;
  TimeOfDay? _weekendWakeTime;
  
  List<String> _selectedConcerns = [];
  String? _caffeineHabit;
  String? _alcoholHabit;
  String? _exerciseHabit;

  // 睡眠の悩みの選択肢
  final List<String> _sleepConcerns = [
    '寝つきが悪い',
    '夜中に目が覚める',
    '朝早く目が覚めてしまう',
    '朝起きるのが辛い',
    '日中の眠気',
    '睡眠時間が短い',
    '睡眠の質が悪い',
    '特に悩みはない',
  ];

  // 習慣の選択肢
  final List<String> _habitOptions = [
    'ほぼ毎日',
    '週に数回',
    'たまに',
    'しない',
  ];

  // 運動習慣の選択肢
  final List<String> _exerciseOptions = [
    'ほぼ毎日',
    '週に3-4回',
    '週に1-2回',
    '月に数回',
    'ほとんどしない',
  ];

  bool get _canProceed =>
      _weekdayBedtime != null &&
      _weekdayWakeTime != null &&
      _weekendBedtime != null &&
      _weekendWakeTime != null &&
      _selectedConcerns.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('睡眠・生活習慣'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // プログレスバー
          const OnboardingProgressBar(currentStep: 2, totalSteps: 4),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '睡眠・生活習慣について',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'あなたの睡眠パターンを理解するために教えてください',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 就寝・起床時刻
                  _buildSectionTitle('普段の就寝・起床時刻', isRequired: true),
                  const SizedBox(height: 16),
                  _buildTimeSection('平日', _weekdayBedtime, _weekdayWakeTime, (bedtime, wakeTime) {
                    setState(() {
                      _weekdayBedtime = bedtime;
                      _weekdayWakeTime = wakeTime;
                    });
                  }),
                  const SizedBox(height: 16),
                  _buildTimeSection('休日', _weekendBedtime, _weekendWakeTime, (bedtime, wakeTime) {
                    setState(() {
                      _weekendBedtime = bedtime;
                      _weekendWakeTime = wakeTime;
                    });
                  }),
                  const SizedBox(height: 32),

                  // 睡眠の悩み
                  _buildSectionTitle('睡眠に関する主な悩み', isRequired: true),
                  const SizedBox(height: 12),
                  _buildMultiChoiceSection(_sleepConcerns, _selectedConcerns, (concerns) {
                    setState(() {
                      _selectedConcerns = concerns;
                    });
                  }),
                  const SizedBox(height: 32),

                  // カフェイン摂取習慣
                  _buildSectionTitle('カフェイン摂取習慣', isRequired: false),
                  const SizedBox(height: 12),
                  _buildSingleChoiceSection(_habitOptions, _caffeineHabit, (value) {
                    setState(() {
                      _caffeineHabit = value;
                    });
                  }),
                  const SizedBox(height: 32),

                  // アルコール摂取習慣
                  _buildSectionTitle('アルコール摂取習慣', isRequired: false),
                  const SizedBox(height: 12),
                  _buildSingleChoiceSection(_habitOptions, _alcoholHabit, (value) {
                    setState(() {
                      _alcoholHabit = value;
                    });
                  }),
                  const SizedBox(height: 32),

                  // 運動習慣
                  _buildSectionTitle('運動習慣', isRequired: false),
                  const SizedBox(height: 12),
                  _buildSingleChoiceSection(_exerciseOptions, _exerciseHabit, (value) {
                    setState(() {
                      _exerciseHabit = value;
                    });
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // 次へボタン
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OnboardingPhoneUsageScreen(
                        nickname: widget.nickname,
                        ageGroup: widget.ageGroup,
                        gender: widget.gender,
                        occupation: widget.occupation,
                        weekdayBedtime: _weekdayBedtime!,
                        weekdayWakeTime: _weekdayWakeTime!,
                        weekendBedtime: _weekendBedtime!,
                        weekendWakeTime: _weekendWakeTime!,
                        sleepConcerns: _selectedConcerns,
                        caffeineHabit: _caffeineHabit,
                        alcoholHabit: _alcoholHabit,
                        exerciseHabit: _exerciseHabit,
                      ),
                    ),
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '次へ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimeSection(
    String label,
    TimeOfDay? bedtime,
    TimeOfDay? wakeTime,
    Function(TimeOfDay?, TimeOfDay?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTimeButton(
                  '就寝時刻',
                  bedtime,
                  () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: bedtime ?? const TimeOfDay(hour: 23, minute: 0),
                    );
                    if (time != null) {
                      onChanged(time, wakeTime);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeButton(
                  '起床時刻',
                  wakeTime,
                  () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (time != null) {
                      onChanged(bedtime, time);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay? time, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: time != null ? AppTheme.primaryColor.withOpacity(0.1) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time?.format(context) ?? '--:--',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: time != null ? AppTheme.primaryColor : Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleChoiceSection(
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return InkWell(
          onTap: () => onChanged(option),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
            child: Text(
              option,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiChoiceSection(
    List<String> options,
    List<String> selectedValues,
    Function(List<String>) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return InkWell(
          onTap: () {
            final newSelection = List<String>.from(selectedValues);
            if (isSelected) {
              newSelection.remove(option);
            } else {
              newSelection.add(option);
            }
            onChanged(newSelection);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(20),
              color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            ),
            child: Text(
              option,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}