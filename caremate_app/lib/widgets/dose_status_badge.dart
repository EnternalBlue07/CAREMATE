import 'package:flutter/material.dart';
import '../models/dose_event.dart';
import '../core/theme/app_theme.dart';

class DoseStatusBadge extends StatelessWidget {
  final DoseStatus status;
  final bool compact;

  const DoseStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case DoseStatus.scheduled:
        bg = const Color(0xFFEFF6FF);
        fg = AppTheme.statusScheduled;
        icon = Icons.schedule_rounded;
        break;
      case DoseStatus.commandSent:
        bg = const Color(0xFFF3E8FF);
        fg = AppTheme.statusCommandSent;
        icon = Icons.sensors_rounded;
        break;
      case DoseStatus.dispenseConfirmed:
        bg = const Color(0xFFD1FAE5);
        fg = AppTheme.statusDispensed;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DoseStatus.acknowledged:
        bg = const Color(0xFFECFDF5);
        fg = AppTheme.statusAcknowledged;
        icon = Icons.task_alt_rounded;
        break;
      case DoseStatus.failed:
        bg = const Color(0xFFFEE2E2);
        fg = AppTheme.statusFailed;
        icon = Icons.error_outline_rounded;
        break;
      case DoseStatus.unknown:
        bg = const Color(0xFFF1F5F9);
        fg = AppTheme.statusUnknown;
        icon = Icons.help_outline_rounded;
        break;
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
            Text(
              status.displayName,
              style: TextStyle(
                color: fg,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: fg.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(
            status.displayName,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
