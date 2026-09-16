import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The green "🔒 On-Device" pill badge — appears anywhere analysis is happening.
class OnDeviceBadge extends StatelessWidget {
  final bool compact;

  const OnDeviceBadge({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: compact ? 10 : 12,
            color: AppColors.accent,
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            'On-Device',
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cloud fallback indicator pill (shown when on-device toggle is OFF).
class CloudBadge extends StatelessWidget {
  const CloudBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_outlined, size: 12, color: AppColors.warning),
          const SizedBox(width: 5),
          Text(
            'Cloud Fallback',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
