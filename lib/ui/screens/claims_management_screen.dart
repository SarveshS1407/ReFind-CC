import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/models/item_model.dart';
import '../../core/models/claim_model.dart';
import '../../core/utils/formatters.dart';
import '../../providers/app_providers.dart';
import 'handover_screen.dart';
import 'chat_screen.dart';

class ClaimsManagementScreen extends ConsumerWidget {
  final ItemModel item;

  const ClaimsManagementScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final claimService = ref.watch(claimServiceProvider);

    ref.watch(claimsProvider);
    final claims = currentUser != null
        ? claimService.getClaimsForItem(itemId: item.id, user: currentUser)
        : <ClaimModel>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Review Claims')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: claims.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 34,
                            color: AppTheme.primaryIndigo,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Claims Submitted Yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'When students submit ownership claims on this item, their non-public verification answers will appear here for your private review.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor(context),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  itemCount: claims.length,
                  itemBuilder: (context, index) {
                    final claim = claims[index];
                    return _ClaimReviewCard(item: item, claim: claim);
                  },
                ),
        ),
      ),
    );
  }
}

class _ClaimReviewCard extends ConsumerWidget {
  final ItemModel item;
  final ClaimModel claim;

  const _ClaimReviewCard({required this.item, required this.claim});

  void _showAcceptDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Ownership Claim?'),
        content: Text(
          'Are you sure you want to approve ${claim.claimantName}\'s claim? This will:\n\n'
          '• Transition this item to "Claimed".\n'
          '• Generate a cryptographically secure 6-digit Handover Token for the claimant.\n'
          '• Decline any other pending claims.\n\n'
          'You will verify the 6-digit code in person before handing over the item.',
          style: const TextStyle(height: 1.4, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusReturned,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final reviewer = ref.read(currentUserProvider)!;
              await ref
                  .read(claimsProvider.notifier)
                  .approveClaim(claimId: claim.id, reviewer: reviewer);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.statusReturned,
                    content: Text(
                      'Claim approved! A 6-digit handover OTP was sent to ${claim.claimantName}.',
                    ),
                  ),
                );
              }
            },
            child: const Text('Approve & Generate OTP'),
          ),
        ],
      ),
    );
  }

  void _showRequestMoreInfoDialog(BuildContext context, WidgetRef ref) {
    final infoController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Request More Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify what additional non-public details you need ${claim.claimantName} to provide:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: infoController,
              decoration: const InputDecoration(
                hintText: 'e.g. Please describe what keychain or stickers are attached...',
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
              if (infoController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final reviewer = ref.read(currentUserProvider)!;
              await ref
                  .read(claimsProvider.notifier)
                  .requestMoreInfo(
                    claimId: claim.id,
                    reviewer: reviewer,
                    requestMessage: infoController.text.trim(),
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request dispatched to claimant.'),
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Decline Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify why this verification claim is being declined:',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Verification details did not match...',
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusLost,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final reviewer = ref.read(currentUserProvider)!;
              await ref
                  .read(claimsProvider.notifier)
                  .rejectClaim(
                    claimId: claim.id,
                    reviewer: reviewer,
                    reason: reasonController.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Claim declined.')),
                );
              }
            },
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color statusBg;
    Color statusColor;
    String statusText;

    switch (claim.status) {
      case ClaimStatus.pending:
      case ClaimStatus.underReview:
        statusBg = AppTheme.statusClaimedBgLight;
        statusColor = AppTheme.statusClaimed;
        statusText = 'Under Review';
        break;
      case ClaimStatus.moreInfoNeeded:
        statusBg = AppTheme.syncWarningBg;
        statusColor = AppTheme.syncWarning;
        statusText = 'More Info Requested';
        break;
      case ClaimStatus.approved:
        statusBg = AppTheme.statusReturnedBgLight;
        statusColor = AppTheme.statusReturned;
        statusText = 'Verified / Approved';
        break;
      case ClaimStatus.rejected:
        statusBg = AppTheme.statusLostBgLight;
        statusColor = AppTheme.statusLost;
        statusText = 'Rejected';
        break;
      case ClaimStatus.handedOver:
        statusBg = AppTheme.statusReturnedBgLight;
        statusColor = AppTheme.statusReturned;
        statusText = 'Handover Completed';
        break;
      case ClaimStatus.withdrawn:
        statusBg = AppTheme.surfaceSubtleColor(context);
        statusColor = AppTheme.textMutedColor(context);
        statusText = 'Withdrawn by Claimant';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: claim.isApproved
              ? AppTheme.statusReturned.withValues(alpha: 0.5)
              : AppTheme.borderColor(context),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Claimant name & status chip
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryIndigo.withValues(
                    alpha: 0.1,
                  ),
                  child: Text(
                    claim.claimantName.isNotEmpty ? claim.claimantName[0] : 'S',
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
                        claim.claimantName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                      Text(
                        Formatters.formatDate(claim.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 24, color: AppTheme.borderColor(context)),

            // Submitted Non-Public Answer to Verification Question
            if (claim.answerToQuestion.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.isDark(context)
                      ? AppTheme.surfaceDarkSubtle
                      : AppTheme.statusFoundBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.statusFoundBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lock, size: 14, color: AppTheme.statusFound),
                        SizedBox(width: 6),
                        Text(
                          'Answer to Verification Challenge:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.statusFound,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      claim.answerToQuestion,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Proof description
            Text(
              'Proof & Ownership Explanation:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              claim.proofDescription,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimaryColor(context),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),

            // Action Row
            if (claim.isPending ||
                claim.isUnderReview ||
                claim.isMoreInfoNeeded) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusLost,
                        side: const BorderSide(color: AppTheme.statusLost),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showRejectDialog(context, ref),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryIndigo,
                        side: const BorderSide(color: AppTheme.primaryIndigo),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showRequestMoreInfoDialog(context, ref),
                      child: const Text('Ask More Info'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusReturned,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => _showAcceptDialog(context, ref),
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message Claimant Privately'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(item: item, claim: claim),
                      ),
                    );
                  },
                ),
              ),
            ] else if (claim.isApproved) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Verify Handover Token (OTP)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryIndigo,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HandoverScreen(
                          item: item,
                          claim: claim,
                          isClaimant: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
