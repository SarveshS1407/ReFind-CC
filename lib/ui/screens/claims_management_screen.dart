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

  const ClaimsManagementScreen({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final claimService = ref.watch(claimServiceProvider);
    
    // Watch claims list from provider to reactively rebuild on changes
    ref.watch(claimsProvider);
    final claims = currentUser != null
        ? claimService.getClaimsForItem(itemId: item.id, user: currentUser)
        : <ClaimModel>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Claims'),
      ),
      body: claims.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_outlined,
                          size: 32, color: AppTheme.primaryBlue),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Claims Submitted Yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'When students submit ownership claims on this item, their non-public verification answers will appear here for your review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              itemBuilder: (context, index) {
                final claim = claims[index];
                return _ClaimReviewCard(item: item, claim: claim);
              },
            ),
    );
  }
}

class _ClaimReviewCard extends ConsumerWidget {
  final ItemModel item;
  final ClaimModel claim;

  const _ClaimReviewCard({
    required this.item,
    required this.claim,
  });

  void _showAcceptDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Ownership Claim?'),
        content: Text(
          'Are you sure you want to approve ${claim.claimantName}\'s claim? This will:\n\n'
          '• Transition this item to "Claimed".\n'
          '• Generate a cryptographically secure 6-digit Handover Token for the claimant.\n'
          '• Decline any other pending claims.\n\n'
          'You will verify the 6-digit code in-person before handing over the item.',
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
              await ref.read(claimsProvider.notifier).approveClaim(
                    claimId: claim.id,
                    reviewer: reviewer,
                  );
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

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Claim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify why this verification claim is being declined:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
              await ref.read(claimsProvider.notifier).rejectClaim(
                    claimId: claim.id,
                    reviewer: reviewer,
                    reason: reasonController.text,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Claim declined.'),
                  ),
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
        statusBg = AppTheme.statusClaimedBg;
        statusColor = AppTheme.statusClaimed;
        statusText = 'Under Review';
        break;
      case ClaimStatus.approved:
        statusBg = AppTheme.statusReturnedBg;
        statusColor = AppTheme.statusReturned;
        statusText = 'Verified / Approved';
        break;
      case ClaimStatus.rejected:
        statusBg = AppTheme.statusLostBg;
        statusColor = AppTheme.statusLost;
        statusText = 'Rejected';
        break;
      case ClaimStatus.handedOver:
        statusBg = AppTheme.statusReturnedBg;
        statusColor = AppTheme.statusReturned;
        statusText = 'Handover Completed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: claim.isApproved
              ? AppTheme.statusReturned.withValues(alpha: 0.5)
              : AppTheme.cardBorder,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Claimant name & status chip
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    claim.claimantName.isNotEmpty ? claim.claimantName[0] : 'S',
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
                        claim.claimantName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        Formatters.formatDate(claim.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            const Divider(height: 24),

            // Submitted Non-Public Answer to Verification Question
            if (claim.answerToQuestion.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.statusFoundBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.statusFound.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock,
                            size: 14, color: AppTheme.statusFound),
                        const SizedBox(width: 6),
                        const Text(
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Proof description
            const Text(
              'Proof & Ownership Explanation:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              claim.proofDescription,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Action Row
            if (claim.isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusLost,
                        side: const BorderSide(color: AppTheme.statusLost),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _showRejectDialog(context, ref),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.statusReturned,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _showAcceptDialog(context, ref),
                      child: const Text('Verify & Approve'),
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
                        builder: (_) => ChatScreen(
                          item: item,
                          claim: claim,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (claim.isApproved) ...[
              // Already approved: Finder can jump directly to verify the 6-digit OTP
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.vpn_key_outlined),
                  label: const Text('Validate In-Person Handover OTP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.statusClaimed,
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
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Coordinate Meeting Point'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          item: item,
                          claim: claim,
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
