import 'package:flutter/material.dart';

import '../../core/models/item_model.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/utils/formatters.dart';
import 'status_badge.dart';

class ItemCard extends StatefulWidget {
  final ItemModel item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final category = CategoryConstants.findById(item.category);
    final isDark = AppTheme.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? AppTheme.primaryIndigo
                : AppTheme.borderColor(context),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: _isHovered
              ? (isDark ? AppTheme.darkSubtleShadow : AppTheme.elevatedShadow)
              : (isDark ? const [] : AppTheme.subtleCardShadow),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Badges & Reward Tag
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(type: item.type, compact: true),
                    StatusBadge(status: item.status, compact: true),
                    if (item.syncStatus == SyncStatus.queuedLocally)
                      const StatusBadge(
                        syncStatus: SyncStatus.queuedLocally,
                        compact: true,
                      ),
                    if (item.rewardAmount != null && item.rewardAmount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentAmber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentAmber),
                        ),
                        child: Text(
                          '₹${item.rewardAmount!.toInt()} Reward',
                          style: const TextStyle(
                            color: AppTheme.accentAmber,
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
                            ? (isDark
                                  ? AppTheme.statusLostBgDark
                                  : AppTheme.statusLostBgLight)
                            : (isDark
                                  ? AppTheme.statusFoundBgDark
                                  : AppTheme.statusFoundBgLight),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: item.isLost
                              ? (isDark
                                    ? AppTheme.statusLostBorderDark
                                    : AppTheme.statusLostBorderLight)
                              : (isDark
                                    ? AppTheme.statusFoundBorderDark
                                    : AppTheme.statusFoundBorderLight),
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        color: item.isLost
                            ? AppTheme.statusLost
                            : AppTheme.statusFound,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor(context),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondaryColor(context),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor(context),
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
                      color: AppTheme.textSecondaryColor(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${item.campusLocationName} (Approximate)',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.access_time,
                      size: 13,
                      color: AppTheme.textMutedColor(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      Formatters.formatDate(item.dateReported),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
