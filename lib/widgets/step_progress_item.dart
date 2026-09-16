import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AnalysisStepState { waiting, active, complete, error }

/// Single animated step row for the Analyzing screen progress flow.
class StepProgressItem extends StatelessWidget {
  final String label;
  final AnalysisStepState state;
  final bool showOnDeviceBadge;

  const StepProgressItem({
    super.key,
    required this.label,
    required this.state,
    this.showOnDeviceBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _StepIcon(state: state),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: switch (state) {
                      AnalysisStepState.waiting => AppColors.textMuted,
                      AnalysisStepState.active => AppColors.textPrimary,
                      AnalysisStepState.complete => AppColors.textPrimary,
                      AnalysisStepState.error => AppColors.danger,
                    },
                  ),
                ),
                if (state == AnalysisStepState.active && showOnDeviceBadge) ...[
                  const SizedBox(height: 4),
                  _OnDeviceInlineBadge(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIcon extends StatelessWidget {
  final AnalysisStepState state;
  const _StepIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AnalysisStepState.waiting => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: const Icon(Icons.circle_outlined,
              size: 12, color: AppColors.textMuted),
        ),
      AnalysisStepState.active => SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.accent,
            backgroundColor: AppColors.border,
          ),
        ),
      AnalysisStepState.complete => Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 16, color: Colors.black),
        ),
      AnalysisStepState.error => Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.danger,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
        ),
    };
  }
}

class _OnDeviceInlineBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 10, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            'Analyzing on-device — nothing leaves your machine',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
