import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Color-coded confidence percentage badge.
class ConfidenceBadge extends StatelessWidget {
  final int score; // 0–100
  final bool large;

  const ConfidenceBadge({super.key, required this.score, this.large = false});

  Color get _color {
    if (score >= 80) return AppColors.confidenceHigh;
    if (score >= 50) return AppColors.confidenceMedium;
    return AppColors.confidenceLow;
  }

  Color get _bgColor {
    if (score >= 80) return AppColors.accent.withOpacity(0.1);
    if (score >= 50) return AppColors.warning.withOpacity(0.1);
    return AppColors.textMuted.withOpacity(0.1);
  }

  String get _label {
    if (score >= 80) return 'High';
    if (score >= 50) return 'Medium';
    return 'Low';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 8 : 6,
            height: large ? 8 : 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: large ? 8 : 6),
          Text(
            '$score%',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: large ? 16 : 12,
              fontWeight: FontWeight.w700,
              color: _color,
            ),
          ),
          SizedBox(width: large ? 6 : 4),
          Text(
            _label,
            style: AppTextStyles.labelSmall.copyWith(
              color: _color,
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
