import 'package:flutter/material.dart';

import '../../core/models/item_model.dart';
import '../../core/constants/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final ItemType? type;
  final ItemStatus? status;
  final SyncStatus? syncStatus;
  final bool compact;

  const StatusBadge({
    super.key,
    this.type,
    this.status,
    this.syncStatus,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    if (syncStatus == SyncStatus.queuedLocally) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF451A03) : AppTheme.syncWarningBg,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(
            color: AppTheme.syncWarning.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: compact ? 11 : 13,
              color: AppTheme.syncWarning,
            ),
            const SizedBox(width: 4),
            Text(
              'Queued Offline',
              style: TextStyle(
                color: AppTheme.syncWarning,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (type != null) {
      final isLost = type == ItemType.lost;
      final bg = isLost
          ? (isDark ? AppTheme.statusLostBgDark : AppTheme.statusLostBgLight)
          : (isDark ? AppTheme.statusFoundBgDark : AppTheme.statusFoundBgLight);
      final border = isLost
          ? (isDark
                ? AppTheme.statusLostBorderDark
                : AppTheme.statusLostBorderLight)
          : (isDark
                ? AppTheme.statusFoundBorderDark
                : AppTheme.statusFoundBorderLight);
      final color = isLost ? AppTheme.statusLost : AppTheme.statusFound;

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLost ? Icons.search : Icons.inventory_2_outlined,
              size: compact ? 11 : 13,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              isLost ? 'LOST' : 'FOUND',
              style: TextStyle(
                color: color,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (status != null) {
      Color bg;
      Color border;
      Color text;
      IconData icon;
      String label;

      switch (status!) {
        case ItemStatus.lost:
          bg = isDark ? AppTheme.statusLostBgDark : AppTheme.statusLostBgLight;
          border = isDark
              ? AppTheme.statusLostBorderDark
              : AppTheme.statusLostBorderLight;
          text = AppTheme.statusLost;
          icon = Icons.help_outline;
          label = 'Reported Lost';
          break;
        case ItemStatus.found:
          bg = isDark
              ? AppTheme.statusFoundBgDark
              : AppTheme.statusFoundBgLight;
          border = isDark
              ? AppTheme.statusFoundBorderDark
              : AppTheme.statusFoundBorderLight;
          text = AppTheme.statusFound;
          icon = Icons.check_circle_outline;
          label = 'Available / Found';
          break;
        case ItemStatus.claimed:
          bg = isDark
              ? AppTheme.statusClaimedBgDark
              : AppTheme.statusClaimedBgLight;
          border = isDark
              ? AppTheme.statusClaimedBorderDark
              : AppTheme.statusClaimedBorderLight;
          text = AppTheme.statusClaimed;
          icon = Icons.verified_user_outlined;
          label = 'Claim Verified';
          break;
        case ItemStatus.returned:
          bg = isDark
              ? AppTheme.statusReturnedBgDark
              : AppTheme.statusReturnedBgLight;
          border = isDark
              ? AppTheme.statusReturnedBorderDark
              : AppTheme.statusReturnedBorderLight;
          text = AppTheme.statusReturned;
          icon = Icons.handshake_outlined;
          label = 'Returned to Owner';
          break;
        case ItemStatus.cancelled:
          bg = isDark ? AppTheme.surfaceDarkSubtle : Colors.grey.shade100;
          border = isDark ? AppTheme.cardBorderDark : Colors.grey.shade300;
          text = isDark ? AppTheme.textMutedDark : Colors.grey.shade700;
          icon = Icons.cancel_outlined;
          label = 'Closed';
          break;
      }

      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 14, color: text),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
