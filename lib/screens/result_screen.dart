import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../models/crash_report.dart';
import '../providers/crash_analysis_provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/crash_type_chip.dart';
import '../widgets/diff_viewer.dart';
import '../widgets/code_snippet_card.dart';
import '../widgets/on_device_badge.dart';

class ResultScreen extends StatefulWidget {
  final CrashReport? preloadedReport;

  const ResultScreen({super.key, this.preloadedReport});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _savedToHistory = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CrashAnalysisProvider>();
    final report = widget.preloadedReport ?? provider.lastReport;
    final parsedCtx = provider.parsedContext;
    // Mark as already saved if this is a preloaded (history) report
    if (widget.preloadedReport != null && !_savedToHistory) {
      _savedToHistory = true;
    }

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(
          child: Text('No result available.',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    // Re-parse the patch from stored text
    final patchLines = AnalysisResult.parsePatchText(report.suggestedPatch);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context, '/', (r) => false),
        ),
        actions: [
          if (report.analysisMode == AnalysisMode.onDevice)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: OnDeviceBadge()),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Root cause card
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CrashTypeChip(exceptionType: report.exceptionType),
                    const Spacer(),
                    ConfidenceBadge(score: report.confidenceScore),
                  ],
                ),
                const SizedBox(height: 14),
                Text('Root Cause', style: AppTextStyles.labelSmall),
                const SizedBox(height: 6),
                Text(
                  report.rootCauseSummary,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.sourceFileReference,
                        style: AppTextStyles.codeSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Confidence detail
          _SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Confidence Score', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 6),
                      ConfidenceBadge(score: report.confidenceScore, large: true),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 52,
                  color: AppColors.border,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Analysis Mode', style: AppTextStyles.labelSmall),
                      const SizedBox(height: 6),
                      report.analysisMode == AnalysisMode.onDevice
                          ? const OnDeviceBadge()
                          : const CloudBadge(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Source snippet
          if (parsedCtx != null || report.sourceFileReference.isNotEmpty) ...[
            Text('Source Context',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColors.textMuted, letterSpacing: 0.8)),
            const SizedBox(height: 8),
            CodeSnippetCard(
              snippet: _buildSnippet(report, parsedCtx),
              fileReference: report.sourceFileReference,
            ),
            const SizedBox(height: 12),
          ],

          // Patch diff
          Text('Suggested Fix',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMuted, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          DiffViewer(lines: patchLines),

          const SizedBox(height: 12),

          // Explanation
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline_rounded,
                        size: 16, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text("What happened?",
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.accent)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  report.explanationText,
                  style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          // Row 1: Copy Patch | Save to History
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyPatch(context, report.suggestedPatch),
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy Patch'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _savedToHistory
                    ? OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.check_rounded,
                            size: 18, color: AppColors.accent),
                        label: Text(
                          'Saved',
                          style: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: AppColors.accent, width: 1),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => _saveToHistory(context, report),
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Save to History'),
                      ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: New Analysis (full width)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/', (r) => false),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Analysis'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _buildSnippet(CrashReport report, dynamic parsedCtx) {
    if (parsedCtx != null && parsedCtx.topAppFrames.isNotEmpty) {
      final frames = parsedCtx.topAppFrames.take(3).toList();
      return frames.map((f) => '${f.displayName}(${f.location})').join('\n');
    }
    return '// ${report.sourceFileReference}\n// Root cause location';
  }

  void _saveToHistory(BuildContext context, CrashReport report) async {
    // The report is already auto-saved by CrashAnalysisProvider.analyze().
    // This button surfaces that fact explicitly and refreshes the History tab.
    setState(() => _savedToHistory = true);
    // Refresh HistoryProvider so the tab badge updates immediately
    if (context.mounted) {
      context.read<HistoryProvider>().loadReports();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.accent, size: 18),
              const SizedBox(width: 10),
              Text(
                'Saved to history',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyPatch(BuildContext context, String patch) {
    Clipboard.setData(ClipboardData(text: patch));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Patch copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}
