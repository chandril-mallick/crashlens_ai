import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Exception type chip/label — shows the exception class name.
class CrashTypeChip extends StatelessWidget {
  final String exceptionType;
  final bool small;

  const CrashTypeChip({
    super.key,
    required this.exceptionType,
    this.small = false,
  });

  Color get _color {
    final t = exceptionType.toLowerCase();
    if (t.contains('null') || t.contains('npe')) return AppColors.danger;
    if (t.contains('network') || t.contains('io')) return AppColors.warning;
    if (t.contains('memory') || t.contains('oom')) return const Color(0xFFBB86FC);
    if (t.contains('security')) return AppColors.warning;
    return AppColors.danger;
  }

  IconData get _icon {
    final t = exceptionType.toLowerCase();
    if (t.contains('null')) return Icons.block_rounded;
    if (t.contains('index') || t.contains('bounds')) return Icons.format_list_numbered_rounded;
    if (t.contains('network')) return Icons.wifi_off_rounded;
    if (t.contains('stack') || t.contains('overflow')) return Icons.loop_rounded;
    if (t.contains('cast')) return Icons.transform_rounded;
    if (t.contains('memory')) return Icons.memory_rounded;
    return Icons.bug_report_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: small ? 12 : 14, color: _color),
          SizedBox(width: small ? 5 : 6),
          Text(
            exceptionType,
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
