import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/crash_analysis_provider.dart';
import '../providers/settings_provider.dart';
import '../services/real_analysis_service.dart';
import '../theme/app_theme.dart';
import '../widgets/step_progress_item.dart';
import '../widgets/on_device_badge.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnalysis();
      });
    }
  }

  Future<void> _startAnalysis() async {
    final rawTrace = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    if (rawTrace.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final settings = context.read<SettingsProvider>();
    final provider = context.read<CrashAnalysisProvider>();

    final realEngine = RealAnalysisService(
      allowCloudFallback: !settings.onDeviceOnly,
    );

    await provider.analyze(rawTrace, customLlm: realEngine);

    if (!mounted) return;

    if (provider.currentStep == AnalysisStep.complete) {
      Navigator.pushReplacementNamed(context, '/result');
    } else if (provider.currentStep == AnalysisStep.error) {
      _showError(provider.errorMessage ?? 'Unknown error');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Analysis Failed', style: AppTextStyles.titleLarge),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Consumer<CrashAnalysisProvider>(
            builder: (context, provider, _) {
              final step = provider.currentStep;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Header
                  Text('Analyzing', style: AppTextStyles.displayLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Running on-device analysis pipeline…',
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 32),

                  // Privacy badge — prominent
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analyzing on-device',
                                style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.accent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nothing leaves your machine. No network calls.',
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const OnDeviceBadge(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Step indicators
                  _buildStepList(step),

                  const Spacer(),

                  // Pulsing status text
                  Center(
                    child: Text(
                      step.label,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.accent),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepList(AnalysisStep currentStep) {
    final steps = [
      (AnalysisStep.parsing, 'Parsing stack trace', false),
      (AnalysisStep.locatingContext, 'Locating source context', false),
      (AnalysisStep.runningModel, 'Running on-device model', true),
      (AnalysisStep.rankingFixes, 'Ranking fixes', false),
    ];

    return Column(
      children: steps.map((s) {
        final (stepEnum, label, showBadge) = s;
        final stepIdx = stepEnum.stepIndex;
        final currentIdx = currentStep.stepIndex;

        final state = switch (true) {
          _ when currentStep == AnalysisStep.complete => AnalysisStepState.complete,
          _ when currentIdx == stepIdx => AnalysisStepState.active,
          _ when currentIdx > stepIdx => AnalysisStepState.complete,
          _ => AnalysisStepState.waiting,
        };

        return Column(
          children: [
            StepProgressItem(
              label: label,
              state: state,
              showOnDeviceBadge: showBadge,
            ),
            if (stepIdx < 3)
              Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Container(
                  width: 1.5,
                  height: 20,
                  color: state == AnalysisStepState.complete
                      ? AppColors.accent.withValues(alpha: 0.4)
                      : AppColors.border,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}
