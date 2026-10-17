import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/models/item_model.dart';
import '../../core/models/claim_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/services/item_service.dart';
import '../../providers/app_providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/lifecycle_stepper.dart';
import 'submit_claim_screen.dart';
import 'claims_management_screen.dart';
import 'handover_screen.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final ItemModel item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(itemsListProvider);
    final currentItem = allItems.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    final currentUser = ref.watch(currentUserProvider);
    final category = CategoryConstants.findById(currentItem.category);
    final isReporter = currentUser?.id == currentItem.reporterId;
    final isModerator = currentUser?.isModerator ?? false;
    final isDesktop = AppBreakpoints.isDesktop(context);

    // Get claims for this item
    final claimService = ref.watch(claimServiceProvider);
    final itemClaims = currentUser != null
        ? claimService.getClaimsForItem(
            itemId: currentItem.id,
            user: currentUser,
          )
        : <ClaimModel>[];

    // Check if current user submitted a claim
    ClaimModel? myClaim;
    if (currentUser != null) {
      try {
        myClaim = itemClaims.firstWhere((c) => c.claimantId == currentUser.id);
      } catch (_) {}
    }

    // Smart Recommendations
    final itemService = ref.watch(itemServiceProvider);
    final recommendations = itemService.findPotentialMatches(currentItem);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentItem.isLost ? 'Lost Item Details' : 'Found Item Details',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.desktopContentMaxWidth,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Map & Location Card
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMapCard(currentItem),
                            const SizedBox(height: 20),
                            _buildReporterCard(
                              currentItem,
                              isReporter,
                              myClaim,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      // Right Column: Main Info, Lifecycle & Actions
                      Expanded(
                        flex: 7,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderInfo(currentItem, category),
                            const SizedBox(height: 20),
                            LifecycleStepper(
                              status: currentItem.status,
                              type: currentItem.type,
                            ),
                            const SizedBox(height: 20),
                            _buildDescriptionCard(currentItem),
                            if (currentItem.isFound &&
                                currentItem.verificationQuestion != null) ...[
                              const SizedBox(height: 20),
                              _buildChallengeCard(currentItem),
                            ],
                            const SizedBox(height: 24),
                            _buildActionArea(
                              context,
                              currentItem,
                              isReporter,
                              isModerator,
                              itemClaims,
                              myClaim,
                            ),
                            if (recommendations.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              _buildRecommendations(context, recommendations),
                            ],
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(currentItem, category),
                      const SizedBox(height: 16),
                      LifecycleStepper(
                        status: currentItem.status,
                        type: currentItem.type,
                      ),
                      const SizedBox(height: 20),
                      _buildDescriptionCard(currentItem),
                      if (currentItem.isFound &&
                          currentItem.verificationQuestion != null) ...[
                        const SizedBox(height: 20),
                        _buildChallengeCard(currentItem),
                      ],
                      const SizedBox(height: 20),
                      _buildMapCard(currentItem),
                      const SizedBox(height: 20),
                      _buildReporterCard(currentItem, isReporter, myClaim),
                      const SizedBox(height: 24),
                      if (recommendations.isNotEmpty) ...[
                        _buildRecommendations(context, recommendations),
                        const SizedBox(height: 20),
                      ],
                      _buildActionArea(
                        context,
                        currentItem,
                        isReporter,
                        isModerator,
                        itemClaims,
                        myClaim,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(ItemModel currentItem, ItemCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StatusBadge(type: currentItem.type),
            const SizedBox(width: 8),
            StatusBadge(status: currentItem.status),
            if (currentItem.syncStatus == SyncStatus.queuedLocally) ...[
              const SizedBox(width: 8),
              const StatusBadge(syncStatus: SyncStatus.queuedLocally),
            ],
            const Spacer(),
            if (currentItem.rewardAmount != null &&
                currentItem.rewardAmount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentAmber),
                ),
                child: Text(
                  '₹${currentItem.rewardAmount!.toInt()} Reward',
                  style: const TextStyle(
                    color: AppTheme.accentAmber,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          currentItem.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(category.icon, size: 16, color: AppTheme.primaryTeal),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const Text(' • ', style: TextStyle(color: AppTheme.textMuted)),
            Text(
              Formatters.formatFullDate(currentItem.dateReported),
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: Text(
            currentItem.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Finder Ownership Challenge',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.statusFoundBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.statusFoundBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.help_outline,
                    size: 20,
                    color: AppTheme.statusFound,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentItem.verificationQuestion!,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Zero-Knowledge Privacy: Claim answers are stored in isolated subcollections. Third parties browsing the feed cannot see other students\' proof.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard(ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Campus Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.statusReturnedBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.statusReturnedBorder),
              ),
              child: const Text(
                'Approximate Area',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusReturned,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(
                currentItem.latitude,
                currentItem.longitude,
              ),
              initialZoom: 16.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.codechefvit.finderskeepers',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(currentItem.latitude, currentItem.longitude),
                    radius: 40,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    borderColor: AppTheme.primaryTeal,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(currentItem.latitude, currentItem.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.place, size: 16, color: AppTheme.primaryTeal),
            const SizedBox(width: 6),
            Text(
              currentItem.campusLocationName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReporterCard(
    ItemModel currentItem,
    bool isReporter,
    ClaimModel? myClaim,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reported By',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                child: Text(
                  currentItem.reporterName.isNotEmpty
                      ? currentItem.reporterName[0]
                      : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentItem.reporterName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isReporter || (myClaim?.isApproved ?? false)
                              ? (currentItem.reporterContact ??
                                    'Verified Campus Student')
                              : 'Contact details hidden for privacy',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(
    BuildContext context,
    List<ItemMatchRecommendation> recommendations,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Potential Matching Reports Nearby',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.take(2).map((rec) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.statusFoundBg.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppTheme.statusFoundBorder),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.auto_awesome,
                color: AppTheme.statusFound,
              ),
              title: Text(
                rec.matchedItem.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '${(rec.confidenceScore * 100).toInt()}% Match • ${rec.reason}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(item: rec.matchedItem),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionArea(
    BuildContext context,
    ItemModel currentItem,
    bool isReporter,
    bool isModerator,
    List<ClaimModel> itemClaims,
    ClaimModel? myClaim,
  ) {
    if (isReporter || isModerator) {
      return Column(
        children: [
          if (currentItem.isClaimed) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Verify Physical Handover (Enter Code)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusClaimed,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          HandoverScreen(item: currentItem, isClaimant: false),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.rule_outlined),
              label: Text('Review Incoming Claims (${itemClaims.length})'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClaimsManagementScreen(item: currentItem),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    if (myClaim != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: myClaim.isApproved
              ? AppTheme.statusReturnedBg
              : myClaim.isRejected
              ? AppTheme.statusLostBg
              : AppTheme.statusClaimedBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: myClaim.isApproved
                ? AppTheme.statusReturnedBorder
                : myClaim.isRejected
                ? AppTheme.statusLostBorder
                : AppTheme.statusClaimedBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              myClaim.isApproved
                  ? 'Claim Verified! Show your handover code to the finder.'
                  : myClaim.isRejected
                  ? 'Claim Rejected: ${myClaim.rejectionReason ?? "Details did not match."}'
                  : 'Your claim is currently under review by the finder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: myClaim.isApproved
                    ? AppTheme.statusReturned
                    : myClaim.isRejected
                    ? AppTheme.statusLost
                    : AppTheme.statusClaimed,
              ),
            ),
            if (myClaim.isApproved && myClaim.handoverCode != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.qr_code),
                label: const Text('View Handover Verification Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusReturned,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HandoverScreen(
                        item: currentItem,
                        claim: myClaim,
                        isClaimant: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      );
    }

    if (currentItem.status != ItemStatus.returned) {
      return SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.front_hand_outlined),
          label: Text(
            currentItem.isFound
                ? 'Claim This Item (I am the Owner)'
                : 'I Found This Item (Contact Owner)',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: currentItem.isFound
                ? AppTheme.statusFound
                : AppTheme.statusLost,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SubmitClaimScreen(item: currentItem),
              ),
            );
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusReturnedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'This item has been successfully returned and closed.',
          style: TextStyle(
            color: AppTheme.statusReturned,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
