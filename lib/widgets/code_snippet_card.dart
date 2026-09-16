import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Source code snippet card with an implicated line highlighted in red.
class CodeSnippetCard extends StatelessWidget {
  final String snippet;
  final int? implicatedLineNumber;
  final String? fileReference;

  const CodeSnippetCard({
    super.key,
    required this.snippet,
    this.implicatedLineNumber,
    this.fileReference,
  });

  @override
  Widget build(BuildContext context) {
    final lines = snippet.split('\n');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
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
                const Icon(Icons.insert_drive_file_outlined,
                    size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  fileReference ?? 'Source snippet',
                  style: AppTextStyles.codeSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (implicatedLineNumber != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Line $implicatedLineNumber',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.danger,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Code lines
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
                  children: lines.asMap().entries.map((entry) {
                    final lineText = entry.value;
                    // Highlight lines containing the implicated line comment or that look like the key line
                    final isImplicated = lineText.contains('// Line') ||
                        lineText.contains('Exception') ||
                        lineText.contains('null');
                    return Container(
                      color: isImplicated
                          ? AppColors.lineHighlight
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2.5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '${entry.key + 1}',
                              style: AppTextStyles.codeSmall.copyWith(
                                color: isImplicated
                                    ? AppColors.danger.withValues(alpha: 0.6)
                                    : AppColors.textMuted,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              lineText,
                              style: AppTextStyles.codeSmall.copyWith(
                                color: isImplicated
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
