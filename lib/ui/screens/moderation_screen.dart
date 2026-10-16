import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';
import 'item_details_screen.dart';

class ModerationScreen extends ConsumerWidget {
  const ModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final allItems = ref.watch(itemsListProvider);
    final allClaims = ref.watch(claimsProvider);

    if (currentUser == null || !currentUser.isModerator) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Moderation')),
        body: const Center(
          child: Text('Access restricted to campus security and moderators.'),
        ),
      );
    }

    final totalLost = allItems.where((i) => i.isLost).length;
    final totalFound = allItems.where((i) => i.isFound).length;
    final totalReturned =
        allItems.where((i) => i.status == ItemStatus.returned).length;
    final totalClaims = allClaims.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Moderation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security Officer Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white24,
                  radius: 24,
                  child: Icon(Icons.security, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${currentUser.studentId} • Campus Security Officer',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Overview Metric Tiles
          Row(
            children: [
              _buildStatTile('Lost Items', '$totalLost', AppTheme.statusLost,
                  Icons.search),
              const SizedBox(width: 10),
              _buildStatTile('Found Items', '$totalFound', AppTheme.statusFound,
                  Icons.inventory_2),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatTile('Total Claims', '$totalClaims',
                  AppTheme.statusClaimed, Icons.assignment_outlined),
              const SizedBox(width: 10),
              _buildStatTile('Safely Returned', '$totalReturned',
                  AppTheme.statusReturned, Icons.check_circle_outline),
            ],
          ),
          const SizedBox(height: 24),

          // Moderation Queue & Flagged Items
          const Text(
            'Active Campus Listings & Audit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          ...allItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  '${item.campusLocationName} • Reported by ${item.reporterName}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailsScreen(item: item),
                      ),
                    );
                  },
                  child: const Text('Audit'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatTile(
      String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
