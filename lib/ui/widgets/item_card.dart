import 'package:flutter/material.dart';
import '../../core/models/item_model.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/formatters.dart';
import 'status_badge.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryConstants.findById(item.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Type Badge, Status Badge & Offline indicator
              Row(
                children: [
                  StatusBadge(type: item.type, compact: true),
                  const SizedBox(width: 8),
                  StatusBadge(status: item.status, compact: true),
                  if (item.syncStatus == SyncStatus.queuedLocally) ...[
                    const SizedBox(width: 8),
                    const StatusBadge(syncStatus: SyncStatus.queuedLocally, compact: true),
                  ],
                  const Spacer(),
                  if (item.rewardAmount != null && item.rewardAmount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Text(
                        '₹${item.rewardAmount!.toInt()} Reward',
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Category Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.isLost
                          ? AppTheme.statusLostBg.withValues(alpha: 0.6)
                          : AppTheme.statusFoundBg.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      category.icon,
                      color: item.isLost ? AppTheme.statusLost : AppTheme.statusFound,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description snippet
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Bottom Info: Approximate Campus Location & Time
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: Colors.blueGrey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${item.campusLocationName} (Approximate)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.access_time,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDate(item.dateReported),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
