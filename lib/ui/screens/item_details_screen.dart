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
import 'welcome_auth_screen.dart';

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
                            _buildMapCard(context, currentItem),
                            const SizedBox(height: 20),
                            _buildReporterCard(
                              context,
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
                            _buildHeaderInfo(context, currentItem, category),
                            const SizedBox(height: 20),
                            LifecycleStepper(
                              status: currentItem.status,
                              type: currentItem.type,
                            ),
                            const SizedBox(height: 20),
                            _buildDescriptionCard(context, currentItem),
                            if (currentItem.isFound &&
                                currentItem.verificationQuestion != null) ...[
                              const SizedBox(height: 20),
                              _buildChallengeCard(context, currentItem),
                            ],
                            const SizedBox(height: 24),
                            _buildActionArea(
                              context,
                              ref,
                              currentItem,
                              isReporter,
                              isModerator,
                              itemClaims,
                              myClaim,
                            ),
                            if (recommendations.isNotEmpty) ...[
                              const SizedBox(height: 28),
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
                      _buildHeaderInfo(context, currentItem, category),
                      const SizedBox(height: 16),
                      LifecycleStepper(
                        status: currentItem.status,
                        type: currentItem.type,
                      ),
                      const SizedBox(height: 16),
                      _buildDescriptionCard(context, currentItem),
                      if (currentItem.isFound &&
                          currentItem.verificationQuestion != null) ...[
                        const SizedBox(height: 16),
                        _buildChallengeCard(context, currentItem),
                      ],
                      const SizedBox(height: 16),
                      _buildMapCard(context, currentItem),
                      const SizedBox(height: 16),
                      _buildReporterCard(
                        context,
                        currentItem,
                        isReporter,
                        myClaim,
                      ),
                      const SizedBox(height: 20),
                      _buildActionArea(
                        context,
                        ref,
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
        ),
      ),
    );
  }

  Widget _buildHeaderInfo(
    BuildContext context,
    ItemModel currentItem,
    ItemCategory category,
  ) {
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
                  color: AppTheme.accentAmber.withValues(alpha: 0.12),
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
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimaryColor(context),
            letterSpacing: -0.3,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(category.icon, size: 16, color: AppTheme.primaryIndigo),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            Text(
              ' • ',
              style: TextStyle(color: AppTheme.textMutedColor(context)),
            ),
            Text(
              Formatters.formatFullDate(currentItem.dateReported),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: Text(
            currentItem.description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor(context),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard(BuildContext context, ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.security, size: 16, color: AppTheme.statusFound),
            const SizedBox(width: 6),
            Text(
              'Zero-Knowledge Verification Challenge',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.isDark(context)
                ? AppTheme.surfaceDarkSubtle
                : AppTheme.statusFoundBg.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.statusFound.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Finder posed the following question for potential claimants:',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusFound,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '"${currentItem.verificationQuestion!}"',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Security Guarantee: Correct answers are never published. When you submit a claim, your answer is strictly delivered to the finder in a private verification subcollection.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapCard(BuildContext context, ItemModel currentItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Campus Location (VIT Vellore)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.statusReturnedBgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.statusReturnedBorderLight),
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
            border: Border.all(color: AppTheme.borderColor(context)),
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
                userAgentPackageName: 'com.codechefvit.refind',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(currentItem.latitude, currentItem.longitude),
                    radius: 40,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                    borderColor: AppTheme.primaryIndigo,
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
                        color: AppTheme.primaryIndigo,
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
            const Icon(Icons.place, size: 16, color: AppTheme.primaryIndigo),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                currentItem.campusLocationName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
            // External Google Maps directions button
            TextButton.icon(
              icon: const Icon(Icons.directions, size: 15),
              label: const Text('Directions', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Google Maps navigation target: ${currentItem.campusLocationName} (${currentItem.latitude.toStringAsFixed(4)}, ${currentItem.longitude.toStringAsFixed(4)})',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReporterCard(
    BuildContext context,
    ItemModel currentItem,
    bool isReporter,
    ClaimModel? myClaim,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reported By',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryIndigo.withValues(alpha: 0.1),
                child: Text(
                  currentItem.reporterName.isNotEmpty
                      ? currentItem.reporterName[0]
                      : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryIndigo,
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
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: AppTheme.textMutedColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isReporter || (myClaim?.isApproved ?? false)
                              ? (currentItem.reporterContact ??
                                    'Verified Campus Student')
                              : 'Contact details hidden for privacy',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor(context),
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
        Text(
          'Potential Matching Reports Nearby',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ...recommendations.take(2).map((rec) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.borderColor(context)),
            ),
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryIndigo,
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
    WidgetRef ref,
    ItemModel currentItem,
    bool isReporter,
    bool isModerator,
    List<ClaimModel> itemClaims,
    ClaimModel? myClaim,
  ) {
    final currentUser = ref.watch(currentUserProvider);

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
      Color bg;
      Color border;
      Color text;

      if (myClaim.isApproved) {
        bg = AppTheme.statusReturnedBgLight;
        border = AppTheme.statusReturnedBorderLight;
        text = AppTheme.statusReturned;
      } else if (myClaim.isRejected) {
        bg = AppTheme.statusLostBgLight;
        border = AppTheme.statusLostBorderLight;
        text = AppTheme.statusLost;
      } else if (myClaim.isMoreInfoNeeded) {
        bg = AppTheme.syncWarningBg;
        border = AppTheme.syncWarningBorder;
        text = AppTheme.syncWarning;
      } else {
        bg = AppTheme.statusClaimedBgLight;
        border = AppTheme.statusClaimedBorderLight;
        text = AppTheme.statusClaimed;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          children: [
            Text(
              myClaim.isApproved
                  ? 'Claim Verified! Show your handover code to the finder.'
                  : myClaim.isRejected
                  ? 'Claim Rejected: ${myClaim.rejectionReason ?? "Details did not match."}'
                  : myClaim.isMoreInfoNeeded
                  ? 'Finder requested more information: "${myClaim.moreInfoRequest}"'
                  : 'Your claim is currently under review by the finder.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: text,
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
            if (myClaim.isPending || myClaim.isMoreInfoNeeded) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Withdraw My Claim'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.statusLost,
                ),
                onPressed: () async {
                  await ref
                      .read(claimsProvider.notifier)
                      .withdrawClaim(
                        claimId: myClaim.id,
                        claimant: currentUser!,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Claim withdrawn.')),
                    );
                  }
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
                ? AppTheme.primaryIndigo
                : AppTheme.statusLost,
          ),
          onPressed: () {
            if (currentUser == null) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubmitClaimScreen(item: currentItem),
                ),
              );
            }
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusReturnedBgLight,
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
