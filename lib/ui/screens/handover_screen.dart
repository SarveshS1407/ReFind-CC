import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/models/item_model.dart';
import '../../core/models/claim_model.dart';
import '../../providers/app_providers.dart';

class HandoverScreen extends ConsumerStatefulWidget {
  final ItemModel item;
  final ClaimModel? claim;
  final bool isClaimant;

  const HandoverScreen({
    super.key,
    required this.item,
    this.claim,
    required this.isClaimant,
  });

  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  final _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Please enter all 6 digits.');
      return;
    }

    final reviewer = ref.read(currentUserProvider);
    if (reviewer == null) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(claimsProvider.notifier)
          .verifyHandover(
            itemId: widget.item.id,
            enteredOtp: code,
            reviewer: reviewer,
          );

      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.statusReturned,
                  size: 28,
                ),
                SizedBox(width: 10),
                Text('Handover Verified!'),
              ],
            ),
            content: const Text(
              'The item has been successfully handed over and returned to its verified owner. The lifecycle status has been permanently updated to "Returned".\n\nThank you for keeping our campus honest!',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.statusReturned,
                ),
                onPressed: () {
                  Navigator.pop(ctx); // pop dialog
                  Navigator.pop(context); // pop handover screen
                },
                child: const Text('Complete & Return to Feed'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isClaimant
              ? 'Handover Verification Token'
              : 'Validate In-Person Handover',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: widget.isClaimant
                ? _buildClaimantView()
                : _buildFinderView(),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimantView() {
    final code = widget.claim?.handoverCode ?? '123456';
    final formattedCode = '${code.substring(0, 3)} ${code.substring(3, 6)}';

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.statusReturnedBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.statusReturned.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.verified_user,
            size: 40,
            color: AppTheme.statusReturned,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Your Ownership is Verified!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Show this 6-digit code to the finder when meeting in person to receive your item.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // 6-digit Code Display Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder, width: 2),
            boxShadow: AppTheme.subtleCardShadow,
          ),
          child: Column(
            children: [
              const Text(
                'HANDOVER OTP CODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                formattedCode,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ref: ${widget.item.id.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Campus Safety Guidelines
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentAmber.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentAmber.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 20,
                    color: AppTheme.accentAmber,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Campus Handover Safety Rules',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.accentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBullet(
                'Meet at a well-lit campus security desk (e.g. SJT Ground Floor or Main Gate).',
              ),
              _buildBullet(
                'Physically inspect the item before confirming the 6-digit code with the finder.',
              ),
              _buildBullet(
                'Never share this code via text, WhatsApp, or phone beforehand.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinderView() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.statusClaimedBg,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.statusClaimed.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: const Icon(Icons.pin, size: 40, color: AppTheme.statusClaimed),
        ),
        const SizedBox(height: 20),
        const Text(
          'Confirm Physical Handover',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask the student for their 6-digit Handover Token. Entering the matching code will complete the return.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // OTP Input
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: '••••••',
            errorText: _errorMessage,
          ),
        ),
        const SizedBox(height: 24),

        // Validate Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isVerifying ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusReturned,
            ),
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify Code & Confirm Handover',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
