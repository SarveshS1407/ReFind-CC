import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/models/item_model.dart';
import '../../core/models/claim_model.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../widgets/status_badge.dart';
import '../widgets/lifecycle_stepper.dart';
import 'submit_claim_screen.dart';
import 'claims_management_screen.dart';
import 'handover_screen.dart';

class ItemDetailsScreen extends ConsumerWidget {
  final ItemModel item;

  const ItemDetailsScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch latest item state from provider
    final allItems = ref.watch(itemsListProvider);
    final currentItem = allItems.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );

    final currentUser = ref.watch(currentUserProvider);
    final category = CategoryConstants.findById(currentItem.category);
    final isReporter = currentUser?.id == currentItem.reporterId;
    final isModerator = currentUser?.isModerator ?? false;

    // Get claims for this item
    final claimService = ref.watch(claimServiceProvider);
    final itemClaims = currentUser != null
        ? claimService.getClaimsForItem(
            itemId: currentItem.id,
            user: currentUser,
          )
        : <ClaimModel>[];

    // Check if the current user already claimed this item
    ClaimModel? myClaim;
    if (currentUser != null) {
      try {
        myClaim = itemClaims.firstWhere((c) => c.claimantId == currentUser.id);
      } catch (_) {}
    }

    // Recommendations (bonus feature)
    final itemService = ref.watch(itemServiceProvider);
    final recommendations = itemService.findPotentialMatches(currentItem);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentItem.isLost ? 'Lost Item Details' : 'Found Item Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Type Badges
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
                if (currentItem.rewardAmount != null && currentItem.rewardAmount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade500),
                    ),
                    child: Text(
                      '₹${currentItem.rewardAmount!.toInt()} Reward',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              currentItem.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),

            // Category & Reported Timestamp
            Row(
              children: [
                Icon(category.icon, size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
                const Text(' • ', style: TextStyle(color: Color(0xFF94A3B8))),
                Text(
                  Formatters.formatFullDate(currentItem.dateReported),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Lifecycle Stepper
            LifecycleStepper(
              status: currentItem.status,
              type: currentItem.type,
            ),
            const SizedBox(height: 20),

            // Description
            const Text(
              'Item Description',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Text(
                currentItem.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ownership Verification Question (if Found Item)
            if (currentItem.isFound && currentItem.verificationQuestion != null) ...[
              const Text(
                'Finder Verification Challenge',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.statusFoundBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.statusFound.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline,
                            size: 18, color: AppTheme.statusFound),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentItem.verificationQuestion!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Privacy Protection: When submitting a claim, only the finder can read your answer to verify your ownership.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Approximate Location Map Snippet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Campus Location',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: const Text(
                    'Approximate Campus Area',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(currentItem.latitude, currentItem.longitude),
                  initialZoom: 16.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none, // Static snippet
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
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        borderColor: AppTheme.primaryBlue,
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
                            color: AppTheme.primaryBlue,
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
                const Icon(Icons.place, size: 16, color: AppTheme.primaryBlue),
                const SizedBox(width: 6),
                Text(
                  currentItem.campusLocationName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reporter & Privacy Masking Section
            const Text(
              'Reported By',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    child: Text(
                      currentItem.reporterName.isNotEmpty
                          ? currentItem.reporterName[0]
                          : 'S',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
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
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              isReporter || (myClaim?.isApproved ?? false)
                                  ? (currentItem.reporterContact ?? 'Verified Student')
                                  : 'Contact details hidden for privacy',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
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
            const SizedBox(height: 24),

            // Smart Recommendations (Bonus Feature)
            if (recommendations.isNotEmpty) ...[
              const Text(
                'Potential Matching Reports Nearby',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              ...recommendations.take(2).map((rec) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: Colors.blue.shade50.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade200),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue),
                    title: Text(
                      rec.matchedItem.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
              const SizedBox(height: 20),
            ],

            // Action Buttons
            if (isReporter || isModerator) ...[
              // Reporter / Moderator Actions
              if (currentItem.isClaimed) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.verified_outlined),
                    label: const Text('Verify Physical Handover (Enter Code)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.statusClaimed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HandoverScreen(
                            item: currentItem,
                            isClaimant: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
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
            ] else if (myClaim != null) ...[
              // Current User already claimed this item
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: myClaim.isApproved
                      ? AppTheme.statusReturnedBg
                      : myClaim.isRejected
                          ? AppTheme.statusLostBg
                          : AppTheme.statusClaimedBg,
                  borderRadius: BorderRadius.circular(16),
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
              ),
            ] else if (currentItem.status != ItemStatus.returned) ...[
              // Can submit a claim
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.front_hand_outlined),
                  label: Text(
                    currentItem.isFound ? 'Claim This Item (I am the Owner)' : 'I Found This Item',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: currentItem.isFound
                        ? AppTheme.statusFound
                        : AppTheme.statusLost,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
