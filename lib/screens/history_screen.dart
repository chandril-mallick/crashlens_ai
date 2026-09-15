import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/crash_report.dart';
import '../providers/crash_analysis_provider.dart';
import '../providers/history_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/crash_type_chip.dart';
import '../widgets/on_device_badge.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  /// When [embedded] is true the screen is inside the AppShell's IndexedStack
  /// and should not show its own AppBar (the shell has none — clean tab look).
  final bool embedded;
  const HistoryScreen({super.key, this.embedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded
          ? AppBar(
              title: const Text('History'),
              automaticallyImplyLeading: false,
              actions: [
                Consumer<HistoryProvider>(
                  builder: (_, provider, __) {
                    if (provider.reports.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear all',
                      onPressed: () => _confirmClearAll(context, provider),
                    );
                  },
                ),
              ],
            )
          : AppBar(
              title: const Text('History'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                Consumer<HistoryProvider>(
                  builder: (_, provider, __) {
                    if (provider.reports.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      tooltip: 'Clear all',
                      onPressed: () => _confirmClearAll(context, provider),
                    );
                  },
                ),
              ],
            ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          if (provider.error != null) {
            return _ErrorState(message: provider.error!);
          }

          if (provider.reports.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: provider.reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final report = provider.reports[index];
              return _HistoryTile(
                report: report,
                onTap: () => _openReport(context, report),
                onDelete: () => provider.deleteReport(report.id),
              );
            },
          );
        },
      ),
    );
  }

  void _openReport(BuildContext context, CrashReport report) {
    // Reset provider so result screen reads from preloadedReport
    context.read<CrashAnalysisProvider>().reset();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(preloadedReport: report),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, HistoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear History', style: AppTextStyles.titleLarge),
        content: Text(
          'This will permanently delete all ${provider.reports.length} crash reports.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.clearAll();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CrashReport report;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.report,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y · HH:mm').format(report.timestamp);

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.dangerDim,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CrashTypeChip(
                        exceptionType: report.exceptionType, small: true),
                  ),
                  const SizedBox(width: 8),
                  ConfidenceBadge(score: report.confidenceScore),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.rootCauseSummary,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(dateStr, style: AppTextStyles.labelSmall),
                  const Spacer(),
                  if (report.analysisMode == AnalysisMode.onDevice)
                    const OnDeviceBadge(compact: true)
                  else
                    const CloudBadge(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No analyses yet', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Import a crash log to get started.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/import'),
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: const Text('Import Crash'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.danger),
            const SizedBox(height: 16),
            Text('Error loading history', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
