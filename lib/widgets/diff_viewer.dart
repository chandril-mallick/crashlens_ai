import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../theme/app_theme.dart';

/// Renders a git-style +/- diff view for a suggested patch.
class DiffViewer extends StatelessWidget {
  final List<DiffLine> lines;

  const DiffViewer({super.key, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.code_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text('Suggested Patch', style: AppTextStyles.labelSmall),
                const Spacer(),
                _buildLegendDot(AppColors.diffAddedBorder, 'Added'),
                const SizedBox(width: 12),
                _buildLegendDot(AppColors.diffRemovedBorder, 'Removed'),
              ],
            ),
          ),
          // Diff lines
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: lines.map((line) => _DiffLineWidget(line: line)).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _DiffLineWidget extends StatelessWidget {
  final DiffLine line;
  const _DiffLineWidget({required this.line});

  @override
  Widget build(BuildContext context) {
    final (prefix, bg, fg) = switch (line.type) {
      DiffLineType.added => ('+', AppColors.diffAdded, AppColors.diffAddedBorder),
      DiffLineType.removed => ('-', AppColors.diffRemoved, AppColors.diffRemovedBorder),
      DiffLineType.context => (' ', Colors.transparent, AppColors.textSecondary),
    };

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(
              prefix,
              style: TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              line.content,
              style: AppTextStyles.codeSmall.copyWith(
                color: line.type == DiffLineType.context
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
