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
          title: const Text('My Activity'),
          bottom: TabBar(
            labelColor: AppTheme.primaryBlue,
            indicatorColor: AppTheme.primaryBlue,
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
                    message:
                        'Items you report as lost or found around campus will be listed here.',
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
                    message:
                        'When you claim a found item, your submission and handover OTP will appear here.',
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
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item?.title ?? 'Item #${claim.itemId}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const Spacer(),
                                  _buildClaimBadge(claim.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Submitted ${Formatters.formatDate(claim.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Proof: ${claim.proofDescription}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (claim.isApproved &&
                                  claim.handoverCode != null) ...[
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.vpn_key),
                                  label: const Text('View Handover Code'),
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
                    message:
                        'All reports and state changes are confirmed and synced with the server.',
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
                          child: ListTile(
                            leading: const Icon(
                              Icons.cloud_upload_outlined,
                              color: AppTheme.syncWarning,
                            ),
                            title: Text('Task: ${task.type}'),
                            subtitle: Text(
                              'Queued at ${Formatters.formatDate(task.createdAt)} • Payload: ${task.payload['title'] ?? task.id}',
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

  Widget _buildClaimBadge(ClaimStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case ClaimStatus.pending:
        bg = AppTheme.statusClaimedBg;
        text = AppTheme.statusClaimed;
        label = 'Pending Review';
        break;
      case ClaimStatus.approved:
        bg = AppTheme.statusReturnedBg;
        text = AppTheme.statusReturned;
        label = 'Approved / Verified';
        break;
      case ClaimStatus.rejected:
        bg = AppTheme.statusLostBg;
        text = AppTheme.statusLost;
        label = 'Declined';
        break;
      case ClaimStatus.handedOver:
        bg = AppTheme.statusReturnedBg;
        text = AppTheme.statusReturned;
        label = 'Completed';
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
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}
