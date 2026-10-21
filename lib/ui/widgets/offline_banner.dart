import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../providers/app_providers.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(offlineModeProvider);
    final outboxCount = ref.watch(outboxCountProvider);
    final isDark = AppTheme.isDark(context);

    if (!isOffline && outboxCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: isOffline
          ? (isDark ? const Color(0xFF451A03) : AppTheme.syncWarningBg)
          : (isDark
                ? AppTheme.surfaceDarkSubtle
                : AppTheme.primaryIndigo.withValues(alpha: 0.1)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.wifi_off : Icons.cloud_queue,
            size: 18,
            color: isOffline
                ? AppTheme.syncWarning
                : AppTheme.primaryIndigoLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? (outboxCount > 0
                        ? 'Offline Mode Active • $outboxCount submissions queued locally'
                        : 'Offline Simulation Active (Submissions saved locally)')
                  : '$outboxCount items ready to sync to server',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOffline
                    ? (isDark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFF92400E))
                    : AppTheme.primaryIndigoLight,
              ),
            ),
          ),
          if (outboxCount > 0 && !isOffline)
            TextButton(
              onPressed: () async {
                final count = await ref
                    .read(itemsListProvider.notifier)
                    .syncOfflineQueue();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully synchronized $count items!'),
                      backgroundColor: AppTheme.statusReturned,
                    ),
                  );
                }
              },
              child: const Text(
                'Sync Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
