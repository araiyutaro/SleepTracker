import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// 目覚めの質評価ダイアログ
/// 睡眠終了時に5段階で目覚めの質を評価し、就寝前のスマホ利用時間も記録
class WakeQualityDialog extends StatefulWidget {
  final Function(int rating, int? phoneUsage) onRated;
  final int? initialRating;
  final int? initialPhoneUsage;

  const WakeQualityDialog({
    Key? key,
    required this.onRated,
    this.initialRating,
    this.initialPhoneUsage,
  }) : super(key: key);

  @override
  State<WakeQualityDialog> createState() => _WakeQualityDialogState();
}

class _WakeQualityDialogState extends State<WakeQualityDialog> {
  int? _selectedRating;
  final TextEditingController _phoneUsageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
    if (widget.initialPhoneUsage != null) {
      _phoneUsageController.text = widget.initialPhoneUsage.toString();
    }
  }

  @override
  void dispose() {
    _phoneUsageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      title: Row(
        children: [
          Icon(
            Icons.wb_sunny,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '目覚めの質はいかがでしたか？',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '今朝の目覚めの良さを5段階で評価してください',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          _buildRatingSelector(),
          const SizedBox(height: 16),
          if (_selectedRating != null) _buildRatingDescription(),
          const SizedBox(height: 24),
          _buildPhoneUsageInput(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _selectedRating != null
              ? () {
                  final phoneUsage = int.tryParse(_phoneUsageController.text);
                  widget.onRated(_selectedRating!, phoneUsage);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('記録する'),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final isSelected = _selectedRating == rating;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedRating = rating;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
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

  Widget _buildRatingDescription() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getRatingColor(_selectedRating!).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRatingColor(_selectedRating!).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getRatingIcon(_selectedRating!),
            color: _getRatingColor(_selectedRating!),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getRatingDescription(_selectedRating!),
              style: TextStyle(
                color: _getRatingColor(_selectedRating!),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
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

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'とても悪い - 全く休めた感じがしない';
      case 2:
        return '悪い - 疲労感が残っている';
      case 3:
        return '普通 - まあまあの目覚め';
      case 4:
        return '良い - すっきりと目覚めた';
      case 5:
        return 'とても良い - 完璧な目覚め';
      default:
        return '';
    }
  }

  Widget _buildPhoneUsageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.smartphone,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '就寝前のスマホ利用時間',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _phoneUsageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '例: 30',
                  suffixText: '分',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () {
                _phoneUsageController.clear();
              },
              child: const Text('クリア'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '昨晩、寝る前にスマートフォンを使用した時間を分単位で入力してください（任意）',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}