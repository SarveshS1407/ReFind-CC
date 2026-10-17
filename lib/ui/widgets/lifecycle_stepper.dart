import 'package:flutter/material.dart';

import '../../core/models/item_model.dart';
import '../../core/constants/app_theme.dart';

class LifecycleStepper extends StatelessWidget {
  final ItemStatus status;
  final ItemType type;

  const LifecycleStepper({super.key, required this.status, required this.type});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == ItemStatus.lost || status == ItemStatus.found) {
      currentStep = 1;
    } else if (status == ItemStatus.claimed) {
      currentStep = 3; // Passed verification
    } else if (status == ItemStatus.returned) {
      currentStep = 4; // Fully completed
    }

    final steps = [
      _StepInfo(
        title: type == ItemType.lost ? 'Reported Lost' : 'Reported Found',
        subtitle: 'Listed on campus feed',
        icon: Icons.campaign_outlined,
      ),
      _StepInfo(
        title: 'Claim Submitted',
        subtitle: 'Under finder review',
        icon: Icons.assignment_late_outlined,
      ),
      _StepInfo(
        title: 'Ownership Verified',
        subtitle: 'Handover code generated',
        icon: Icons.verified_user_outlined,
      ),
      _StepInfo(
        title: 'Handed Over',
        subtitle: 'Returned to owner',
        icon: Icons.check_circle_outline,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, size: 18, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Item Lifecycle Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Text(
                'Step ${currentStep.clamp(1, 4)} of 4',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepBefore = index ~/ 2;
                final isPassed = currentStep > stepBefore + 1;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed
                        ? AppTheme.statusReturned
                        : AppTheme.cardBorder,
                  ),
                );
              }

              final stepIndex = index ~/ 2;
              final isCompleted = currentStep > stepIndex + 1;
              final isCurrent = currentStep == stepIndex + 1;

              Color circleBg;
              Color iconColor;
              Border? border;

              if (isCompleted) {
                circleBg = AppTheme.statusReturned;
                iconColor = Colors.white;
              } else if (isCurrent) {
                circleBg = AppTheme.primaryTeal;
                iconColor = Colors.white;
              } else {
                circleBg = Colors.grey.shade100;
                iconColor = Colors.grey.shade400;
                border = Border.all(color: AppTheme.cardBorder, width: 1.5);
              }

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleBg,
                  border: border,
                ),
                child: Icon(
                  isCompleted ? Icons.check : steps[stepIndex].icon,
                  size: 16,
                  color: iconColor,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (i) {
              final isCurrent = currentStep == i + 1;
              return SizedBox(
                width: 70,
                child: Text(
                  steps[i].title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? AppTheme.primaryTeal
                        : const Color(0xFF64748B),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
