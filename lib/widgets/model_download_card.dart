import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_manager_service.dart';
import '../theme/app_theme.dart';

class ModelDownloadCard extends StatelessWidget {
  const ModelDownloadCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ModelManagerService>(
      builder: (context, modelManager, _) {
        final isDownloaded = modelManager.isModelDownloaded;
        final isDownloading = modelManager.isDownloading;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDownloaded ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDownloaded
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDownloaded ? Icons.security_rounded : Icons.download_rounded,
                      color: isDownloaded ? AppColors.accent : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Gemma 2B LLM Bundle',
                              style: AppTextStyles.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDownloaded
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isDownloaded ? 'READY' : 'LOCAL BUNDLE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isDownloaded ? AppColors.accent : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          modelManager.statusMessage,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDownloaded ? AppColors.accent : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Quantized INT4 Gemma 2B model for 100% offline, privacy-first stack trace root-cause analysis.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              if (isDownloading) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: modelManager.downloadProgress > 0 ? modelManager.downloadProgress : null,
                    backgroundColor: AppColors.surfaceElevated,
                    color: AppColors.accent,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Downloading model file…',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${(modelManager.downloadProgress * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.codeMedium.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              ] else if (isDownloaded) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flight_takeoff_rounded, size: 14, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'Airplane Mode Ready (Offline)',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(color: AppColors.danger.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onPressed: () => _confirmDelete(context, modelManager),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      await modelManager.downloadModel();
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Local Model (~1.5 GB)'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, ModelManagerService modelManager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Model File?', style: AppTextStyles.titleLarge),
        content: Text(
          'This will remove the downloaded Gemma 2B model from local storage. You can re-download it anytime.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              modelManager.deleteModel();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
