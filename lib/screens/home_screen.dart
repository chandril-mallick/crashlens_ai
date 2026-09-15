import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/on_device_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Logo / wordmark
              _CrashLensLogo(),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Privacy-first Android crash analysis.\nRunning entirely on your device.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 8),
              const OnDeviceBadge(),

              const Spacer(),

              // Hero illustration placeholder
              Center(
                child: _HeroIllustration(),
              ),

              const Spacer(),

              // Primary CTA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/import'),
                  icon: const Icon(Icons.upload_file_outlined, size: 20),
                  label: const Text('Import Crash Log'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrashLensLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Crash',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textPrimary,
              fontSize: 36,
            ),
          ),
          TextSpan(
            text: 'Lens',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.accent,
              fontSize: 36,
            ),
          ),
          TextSpan(
            text: ' AI',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textMuted,
              fontSize: 24,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          // Fake terminal header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _dot(AppColors.danger),
                const SizedBox(width: 6),
                _dot(AppColors.warning),
                const SizedBox(width: 6),
                _dot(AppColors.accent),
                const SizedBox(width: 12),
                Text(
                  'logcat — crash.log',
                  style: AppTextStyles.codeSmall.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Fake log lines
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _logLine('FATAL EXCEPTION: main', AppColors.danger),
                _logLine('java.lang.NullPointerException:', AppColors.danger),
                _logLine('  at MainActivity.onCreate(:42)', AppColors.textSecondary),
                _logLine('  at ActivityThread.performLaunch', AppColors.textMuted),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Root cause identified',
                      style: AppTextStyles.codeSmall.copyWith(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _logLine(String text, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          text,
          style: AppTextStyles.codeSmall.copyWith(color: color, fontSize: 11),
        ),
      );
}
