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
    if (syncStatus == SyncStatus.queuedLocally) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: AppTheme.syncWarningBg,
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
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 10,
          vertical: compact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: isLost ? AppTheme.statusLostBg : AppTheme.statusFoundBg,
          borderRadius: BorderRadius.circular(compact ? 6 : 8),
          border: Border.all(
            color: isLost
                ? AppTheme.statusLost.withValues(alpha: 0.3)
                : AppTheme.statusFound.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLost ? Icons.search : Icons.inventory_2_outlined,
              size: compact ? 11 : 13,
              color: isLost ? AppTheme.statusLost : AppTheme.statusFound,
            ),
            const SizedBox(width: 4),
            Text(
              isLost ? 'LOST' : 'FOUND',
              style: TextStyle(
                color: isLost ? AppTheme.statusLost : AppTheme.statusFound,
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
      Color text;
      IconData icon;
      String label;

      switch (status!) {
        case ItemStatus.lost:
          bg = AppTheme.statusLostBg;
          text = AppTheme.statusLost;
          icon = Icons.help_outline;
          label = 'Reported Lost';
          break;
        case ItemStatus.found:
          bg = AppTheme.statusFoundBg;
          text = AppTheme.statusFound;
          icon = Icons.check_circle_outline;
          label = 'Available / Found';
          break;
        case ItemStatus.claimed:
          bg = AppTheme.statusClaimedBg;
          text = AppTheme.statusClaimed;
          icon = Icons.verified_user_outlined;
          label = 'Claim Verified';
          break;
        case ItemStatus.returned:
          bg = AppTheme.statusReturnedBg;
          text = AppTheme.statusReturned;
          icon = Icons.handshake_outlined;
          label = 'Returned to Owner';
          break;
        case ItemStatus.cancelled:
          bg = Colors.grey.shade100;
          text = Colors.grey.shade700;
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
          border: Border.all(color: text.withValues(alpha: 0.25)),
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
