import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/models/claim_model.dart';
import '../../core/models/item_model.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import '../widgets/item_card.dart';
import '../widgets/empty_state.dart';
import 'item_details_screen.dart';
import 'handover_screen.dart';

class MyActivityScreen extends ConsumerWidget {
  const MyActivityScreen({super.key});

  void _showRespondDialog(
    BuildContext context,
    WidgetRef ref,
    ClaimModel claim,
  ) {
    final responseController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Respond to Finder Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Finder requested: "${claim.moreInfoRequest ?? "Additional evidence"}"',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: responseController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your additional proof or identifying answers here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (responseController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final claimant = ref.read(currentUserProvider)!;
              await ref
                  .read(claimsProvider.notifier)
                  .respondToMoreInfo(
                    claimId: claim.id,
                    claimant: claimant,
                    responseMessage: responseController.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Response submitted to finder.'),
                  ),
                );
              }
            },
            child: const Text('Submit Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final allItems = ref.watch(itemsListProvider);
    final claimService = ref.watch(claimServiceProvider);
    final storage = ref.watch(localStorageServiceProvider);

    ref.watch(claimsProvider); // React to claim changes

    final myReportedItems = currentUser != null
        ? allItems.where((i) => i.reporterId == currentUser.id).toList()
        : <ItemModel>[];

    final mySubmittedClaims = currentUser != null
        ? claimService.getMySubmittedClaims(currentUser.id)
        : <ClaimModel>[];

    final outboxTasks = storage.getOutboxTasks();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Campus Activity'),
          bottom: TabBar(
            labelColor: AppTheme.primaryIndigoLight,
            unselectedLabelColor: AppTheme.textSecondaryColor(context),
            indicatorColor: AppTheme.primaryIndigoLight,
            tabs: [
              Tab(text: 'Reports (${myReportedItems.length})'),
              Tab(text: 'Claims (${mySubmittedClaims.length})'),
              Tab(text: 'Outbox (${outboxTasks.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: My Reported Items
            myReportedItems.isEmpty
                ? const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No Items Reported Yet',
                    message: 'Items you report as lost or found around campus will be listed here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: myReportedItems.length,
                    itemBuilder: (context, index) {
                      final item = myReportedItems[index];
                      return ItemCard(
                        item: item,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailsScreen(item: item),
                            ),
                          );
                        },
                      );
                    },
                  ),

            // Tab 2: My Claims
            mySubmittedClaims.isEmpty
                ? const EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Claims Submitted',
                    message: 'When you claim a found item, your submission and handover OTP will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: mySubmittedClaims.length,
                    itemBuilder: (context, index) {
                      final claim = mySubmittedClaims[index];
                      final item = ref
                          .read(itemServiceProvider)
                          .getItemById(claim.itemId);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.cardColor(context),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item?.title ?? 'Item #${claim.itemId}',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimaryColor(context),
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildClaimBadge(context, claim.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Submitted ${Formatters.formatDate(claim.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Proof: ${claim.proofDescription}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (claim.isMoreInfoNeeded) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.syncWarningBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.syncWarningBorder,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info,
                                        size: 16,
                                        color: AppTheme.syncWarning,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Finder: "${claim.moreInfoRequest}"',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.reply, size: 16),
                                  label: const Text('Respond with More Info'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryIndigo,
                                  ),
                                  onPressed: () =>
                                      _showRespondDialog(context, ref, claim),
                                ),
                              ],
                              if (claim.isApproved &&
                                  claim.handoverCode != null) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.vpn_key),
                                  label: const Text(
                                    'View 6-Digit Handover OTP',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.statusReturned,
                                  ),
                                  onPressed: () {
                                    if (item != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => HandoverScreen(
                                            item: item,
                                            claim: claim,
                                            isClaimant: true,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                              if (claim.isPending ||
                                  claim.isMoreInfoNeeded) ...[
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () async {
                                    await ref
                                        .read(claimsProvider.notifier)
                                        .withdrawClaim(
                                          claimId: claim.id,
                                          claimant: currentUser!,
                                        );
                                  },
                                  child: const Text(
                                    'Withdraw Claim',
                                    style: TextStyle(
                                      color: AppTheme.statusLost,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),

            // Tab 3: Outbox Queue
            outboxTasks.isEmpty
                ? const EmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Outbox is Clear',
                    message: 'All reports and state changes are confirmed and synced with the server.',
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.sync),
                        label: const Text('Synchronize Outbox Now'),
                        onPressed: () async {
                          final count = await ref
                              .read(itemsListProvider.notifier)
                              .syncOfflineQueue();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Synced $count items!'),
                                backgroundColor: AppTheme.statusReturned,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ...outboxTasks.map((task) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: AppTheme.cardColor(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.borderColor(context),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppTheme.syncWarning,
                            ),
                            title: Text(
                              'Task: ${task.type}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                            subtitle: Text(
                              'Queued at ${Formatters.formatDate(task.createdAt)} • Payload: ${task.payload['title'] ?? task.id}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor(context),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildClaimBadge(BuildContext context, ClaimStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case ClaimStatus.pending:
      case ClaimStatus.underReview:
        bg = AppTheme.statusClaimedBgLight;
        text = AppTheme.statusClaimed;
        label = 'Pending Review';
        break;
      case ClaimStatus.moreInfoNeeded:
        bg = AppTheme.syncWarningBg;
        text = AppTheme.syncWarning;
        label = 'More Info Needed';
        break;
      case ClaimStatus.approved:
        bg = AppTheme.statusReturnedBgLight;
        text = AppTheme.statusReturned;
        label = 'Approved / Verified';
        break;
      case ClaimStatus.rejected:
        bg = AppTheme.statusLostBgLight;
        text = AppTheme.statusLost;
        label = 'Declined';
        break;
      case ClaimStatus.handedOver:
        bg = AppTheme.statusReturnedBgLight;
        text = AppTheme.statusReturned;
        label = 'Completed';
        break;
      case ClaimStatus.withdrawn:
        bg = AppTheme.surfaceSubtleColor(context);
        text = AppTheme.textMutedColor(context);
        label = 'Withdrawn';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
    );
  }
}
