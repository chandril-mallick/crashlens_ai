import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/on_device_badge.dart';

import '../widgets/model_download_card.dart';

class SettingsScreen extends StatelessWidget {
  final bool embedded;
  const SettingsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: !embedded,
        leading: embedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // Privacy section
              _SectionHeader(label: 'PRIVACY & INFERENCE'),

              // ON-DEVICE TOGGLE — the hero demo beat
              _ToggleCard(
                icon: Icons.lock_rounded,
                iconColor: settings.onDeviceOnly
                    ? AppColors.accent
                    : AppColors.textMuted,
                title: 'Run on-device only',
                subtitle: settings.onDeviceOnly
                    ? 'Crash logs never leave your device. Analysis uses the local model.'
                    : 'Cloud fallback enabled. Logs may be sent to a remote API.',
                value: settings.onDeviceOnly,
                onChanged: settings.setOnDeviceOnly,
                badge: settings.onDeviceOnly
                    ? const OnDeviceBadge()
                    : const CloudBadge(),
                warning: !settings.onDeviceOnly
                    ? 'Warning: cloud fallback sends crash data to a remote server.'
                    : null,
              ),

              const SizedBox(height: 16),

              // Local Model Download Card
              _SectionHeader(label: 'ON-DEVICE MODEL MANAGEMENT'),
              const ModelDownloadCard(),

              const SizedBox(height: 16),

              // Model info
              _SectionHeader(label: 'MODEL INFO'),
              _InfoCard(
                children: [
                  _InfoRow(
                    icon: Icons.memory_rounded,
                    label: 'Model',
                    value: settings.modelName,
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.storage_rounded,
                    label: 'Size',
                    value: settings.modelSize,
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Status',
                    value: settings.modelStatus,
                    valueColor: AppColors.accent,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // About / privacy statement
              _SectionHeader(label: 'ABOUT'),
              _InfoCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 18, color: AppColors.accent),
                            const SizedBox(width: 10),
                            Text(
                              'Privacy Statement',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'CrashLens AI performs all crash analysis locally on this device. '
                          'Your crash logs, stack traces, and source code are never '
                          'uploaded to any server unless you explicitly enable '
                          'cloud fallback mode above.\n\n'
                          'All analysis history is stored in a local SQLite database '
                          'on this device and never transmitted externally.',
                          style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Version',
                    value: '1.0.0 (MVP)',
                  ),
                  _divider(),
                  _InfoRow(
                    icon: Icons.build_circle_outlined,
                    label: 'Built for',
                    value: 'Android (Flutter)',
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() => const Divider(
        height: 1,
        indent: 16,
        endIndent: 0,
        color: AppColors.border,
      );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          letterSpacing: 1.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Future<void> Function(bool) onChanged;
  final Widget? badge;
  final String? warning;

  const _ToggleCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.badge,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.accent.withValues(alpha: 0.3) : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          if (badge != null || warning != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                children: [
                  if (badge != null) badge!,
                  if (warning != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        warning!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label, style: AppTextStyles.bodyMedium),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
