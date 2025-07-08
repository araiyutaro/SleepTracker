import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';
import '../../widgets/onboarding_progress_bar.dart';
import 'onboarding_sleep_habits_screen.dart';

class OnboardingBasicInfoScreen extends StatefulWidget {
  final String? nickname;

  const OnboardingBasicInfoScreen({
    Key? key,
    this.nickname,
  }) : super(key: key);

  @override
  State<OnboardingBasicInfoScreen> createState() => _OnboardingBasicInfoScreenState();
}

class _OnboardingBasicInfoScreenState extends State<OnboardingBasicInfoScreen> {
  String? _selectedAgeGroup;
  String? _selectedGender;
  String? _selectedOccupation;

  // 年齢グループの選択肢
  final List<String> _ageGroups = [
    '10代以下',
    '20代',
    '30代',
    '40代',
    '50代',
    '60代以上',
  ];

  // 性別の選択肢
  final List<String> _genders = [
    '男性',
    '女性',
    'その他',
    '回答しない',
  ];

  // 職業の選択肢
  final List<String> _occupations = [
    '会社員（デスクワーク）',
    '会社員（現場作業）',
    'シフト勤務',
    '自営業・フリーランス',
    '学生',
    '主婦・主夫',
    'その他',
  ];

  bool get _canProceed => _selectedAgeGroup != null && _selectedGender != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基本情報'),
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
          const OnboardingProgressBar(currentStep: 1, totalSteps: 4),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'あなたのことを教えてください',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'より良い睡眠分析のために、基本的な情報を教えてください',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 年齢グループ選択
                  _buildSectionTitle('年齢', isRequired: true),
                  const SizedBox(height: 8),
                  _buildSingleChoiceSection(_ageGroups, _selectedAgeGroup, (value) {
                    setState(() {
                      _selectedAgeGroup = value;
                    });
                  }),
                  const SizedBox(height: 20),

                  // 性別選択
                  _buildSectionTitle('性別', isRequired: true),
                  const SizedBox(height: 8),
                  _buildSingleChoiceSection(_genders, _selectedGender, (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  }),
                  const SizedBox(height: 20),

                  // 職業選択
                  _buildSectionTitle('職業', isRequired: false),
                  const SizedBox(height: 8),
                  _buildSingleChoiceSection(_occupations, _selectedOccupation, (value) {
                    setState(() {
                      _selectedOccupation = value;
                    });
                  }),
                  const SizedBox(height: 80), // ボタン分の余裕を追加
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
                      builder: (context) => OnboardingSleepHabitsScreen(
                        nickname: widget.nickname,
                        ageGroup: _selectedAgeGroup!,
                        gender: _selectedGender!,
                        occupation: _selectedOccupation,
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
}