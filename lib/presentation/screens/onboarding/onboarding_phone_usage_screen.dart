import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../widgets/onboarding_progress_bar.dart';
import 'onboarding_completion_screen.dart';

class OnboardingPhoneUsageScreen extends StatefulWidget {
  final String? nickname;
  final String ageGroup;
  final String gender;
  final String? occupation;
  final TimeOfDay weekdayBedtime;
  final TimeOfDay weekdayWakeTime;
  final TimeOfDay weekendBedtime;
  final TimeOfDay weekendWakeTime;
  final List<String> sleepConcerns;
  final String? caffeineHabit;
  final String? alcoholHabit;
  final String? exerciseHabit;

  const OnboardingPhoneUsageScreen({
    Key? key,
    this.nickname,
    required this.ageGroup,
    required this.gender,
    this.occupation,
    required this.weekdayBedtime,
    required this.weekdayWakeTime,
    required this.weekendBedtime,
    required this.weekendWakeTime,
    required this.sleepConcerns,
    this.caffeineHabit,
    this.alcoholHabit,
    this.exerciseHabit,
  }) : super(key: key);

  @override
  State<OnboardingPhoneUsageScreen> createState() => _OnboardingPhoneUsageScreenState();
}

class _OnboardingPhoneUsageScreenState extends State<OnboardingPhoneUsageScreen> {
  String? _phoneUsageTime;
  List<String> _selectedUsageContent = [];

  // 利用時間の選択肢
  final List<String> _usageTimeOptions = [
    '15分未満',
    '15分～30分',
    '30分～1時間',
    '1時間～2時間',
    '2時間以上',
  ];

  // 利用コンテンツの選択肢
  final List<String> _usageContentOptions = [
    'SNS（Twitter、Instagram等）',
    '動画視聴（YouTube、Netflix等）',
    'ゲーム',
    'ニュース・記事を読む',
    'メッセージ・メール',
    '音楽・ポッドキャスト',
    'ショッピング',
    'その他',
  ];

  bool get _canProceed => _phoneUsageTime != null && _selectedUsageContent.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スマホ利用習慣'),
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
          const OnboardingProgressBar(currentStep: 3, totalSteps: 4),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'スマホ利用習慣について',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '就寝前のスマホ利用について教えてください',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 利用時間
                  _buildSectionTitle('就寝前のスマホ利用時間', isRequired: true),
                  const SizedBox(height: 8),
                  _buildSingleChoiceSection(_usageTimeOptions, _phoneUsageTime, (value) {
                    setState(() {
                      _phoneUsageTime = value;
                    });
                  }),
                  const SizedBox(height: 20),

                  // 利用コンテンツ
                  _buildSectionTitle('就寝前にスマホで主にすること', isRequired: true),
                  const SizedBox(height: 4),
                  Text(
                    '複数選択できます',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMultiChoiceSection(_usageContentOptions, _selectedUsageContent, (content) {
                    setState(() {
                      _selectedUsageContent = content;
                    });
                  }),
                  const SizedBox(height: 80), // ボタン分の余裕を追加
                ],
              ),
            ),
          ),

          // 完了ボタン
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canProceed ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => OnboardingCompletionScreen(
                        nickname: widget.nickname,
                        ageGroup: widget.ageGroup,
                        gender: widget.gender,
                        occupation: widget.occupation,
                        weekdayBedtime: widget.weekdayBedtime,
                        weekdayWakeTime: widget.weekdayWakeTime,
                        weekendBedtime: widget.weekendBedtime,
                        weekendWakeTime: widget.weekendWakeTime,
                        sleepConcerns: widget.sleepConcerns,
                        caffeineHabit: widget.caffeineHabit,
                        alcoholHabit: widget.alcoholHabit,
                        exerciseHabit: widget.exerciseHabit,
                        phoneUsageTime: _phoneUsageTime!,
                        phoneUsageContent: _selectedUsageContent,
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
                  '完了',
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

  Widget _buildSingleChoiceSection(
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedValue == option;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.primaryColor : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
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
    return Column(
      children: options.map((option) {
        final isSelected = selectedValues.contains(option);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              final newSelection = List<String>.from(selectedValues);
              if (isSelected) {
                newSelection.remove(option);
              } else {
                newSelection.add(option);
              }
              onChanged(newSelection);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? AppTheme.primaryColor : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppTheme.primaryColor : null,
                        fontWeight: isSelected ? FontWeight.w600 : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}