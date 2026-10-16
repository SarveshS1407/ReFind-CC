import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';

class SubmitClaimScreen extends ConsumerStatefulWidget {
  final ItemModel item;

  const SubmitClaimScreen({
    super.key,
    required this.item,
  });

  @override
  ConsumerState<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends ConsumerState<SubmitClaimScreen> {
  final _formKey = GlobalKey<FormState>();
  final _proofController = TextEditingController();
  final _answerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _proofController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to submit a claim.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(claimsProvider.notifier).submitClaim(
            itemId: widget.item.id,
            claimant: currentUser,
            proofDescription: _proofController.text.trim(),
            answerToQuestion: _answerController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.statusReturned,
            content: Text(
              'Claim submitted! The finder has been notified to review your verification details.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.statusLost,
            content: Text('Claim failed: ${e.toString().replaceAll("Exception: ", "")}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Ownership Claim'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Item Summary Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 24, color: AppTheme.primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Found near: ${item.campusLocationName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Non-Public Challenge Section
              if (item.verificationQuestion != null &&
                  item.verificationQuestion!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.statusFoundBg.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.statusFound.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 18, color: AppTheme.statusFound),
                          const SizedBox(width: 8),
                          const Text(
                            'Finder Verification Question',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusFound,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.verificationQuestion!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Your Answer (Kept Strictly Non-Public) *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _answerController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Provide the exact answer known only to the owner...',
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please answer the verification question to prove ownership.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Proof Description
              const Text(
                'Proof of Ownership & Details *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Describe distinguishing marks, scratches, stickers, or personal items inside that prove this item belongs to you.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _proofController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'e.g. Has a small crack on the bottom left corner, inside there is a library card with reg no 23BCE1042...',
                ),
                validator: (val) {
                  if (val == null || val.trim().length < 10) {
                    return 'Please provide a detailed explanation (at least 10 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Privacy & Security Guarantee Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 20, color: AppTheme.primaryBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zero-Exposure Policy: Your claim description and answers are stored securely and will NEVER be publicly shown or revealed to other claimants.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitClaim,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Ownership Verification Claim',
                          style: TextStyle(fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
