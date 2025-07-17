import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

/// 目覚めの質評価ダイアログ
/// 睡眠終了時に5段階で目覚めの質を評価
class WakeQualityDialog extends StatefulWidget {
  final Function(int) onRated;
  final int? initialRating;

  const WakeQualityDialog({
    Key? key,
    required this.onRated,
    this.initialRating,
  }) : super(key: key);

  @override
  State<WakeQualityDialog> createState() => _WakeQualityDialogState();
}

class _WakeQualityDialogState extends State<WakeQualityDialog> {
  int? _selectedRating;

  @override
  void initState() {
    super.initState();
    _selectedRating = widget.initialRating;
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
                  widget.onRated(_selectedRating!);
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
}