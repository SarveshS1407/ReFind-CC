import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../providers/app_providers.dart';
import 'home_feed_screen.dart';
import 'map_screen.dart';
import 'report_item_screen.dart';
import 'my_activity_screen.dart';
import 'help_screen.dart';
import 'moderation_screen.dart';
import 'auth_screen.dart';

class ResponsiveMainScreen extends ConsumerStatefulWidget {
  const ResponsiveMainScreen({super.key});

  @override
  ConsumerState<ResponsiveMainScreen> createState() =>
      _ResponsiveMainScreenState();
}

class _ResponsiveMainScreenState extends ConsumerState<ResponsiveMainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isModerator = currentUser?.isModerator ?? false;
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isOffline = ref.watch(offlineModeProvider);

    // Dynamic destination items
    final destinations = [
      const _NavigationItem(
        icon: Icons.feed_outlined,
        selectedIcon: Icons.feed,
        label: 'Feed',
      ),
      const _NavigationItem(
        icon: Icons.map_outlined,
        selectedIcon: Icons.map,
        label: 'Map',
      ),
      const _NavigationItem(
        icon: Icons.add_circle_outline,
        selectedIcon: Icons.add_circle,
        label: 'Report',
      ),
      const _NavigationItem(
        icon: Icons.assignment_outlined,
        selectedIcon: Icons.assignment,
        label: 'Activity',
      ),
      const _NavigationItem(
        icon: Icons.help_outline,
        selectedIcon: Icons.help,
        label: 'Help',
      ),
      if (isModerator)
        const _NavigationItem(
          icon: Icons.shield_outlined,
          selectedIcon: Icons.shield,
          label: 'Moderation',
        ),
    ];

    // Bound check for selected index when switching roles
    if (_selectedIndex >= destinations.length) {
      _selectedIndex = 0;
    }

    Widget contentWidget;
    switch (_selectedIndex) {
      case 0:
        contentWidget = const HomeFeedScreen();
        break;
      case 1:
        contentWidget = const MapScreen();
        break;
      case 2:
        contentWidget = const ReportItemScreen();
        break;
      case 3:
        contentWidget = const MyActivityScreen();
        break;
      case 4:
        contentWidget = const HelpScreen(showBackButton: false);
        break;
      case 5:
        contentWidget = isModerator
            ? const ModerationScreen()
            : const HomeFeedScreen();
        break;
      default:
        contentWidget = const HomeFeedScreen();
    }

    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            // Desktop Header Bar
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
                boxShadow: AppTheme.subtleCardShadow,
              ),
              child: Row(
                children: [
                  // App Brand
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryTeal,
                          AppTheme.primaryTealLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.travel_explore,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finders Keepers?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'VIT Campus Lost & Found Network',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40),

                  // Desktop Navigation Tabs
                  Expanded(
                    child: Row(
                      children: List.generate(destinations.length, (index) {
                        final item = destinations[index];
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedIndex = index),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryTeal.withValues(
                                        alpha: 0.08,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    size: 18,
                                    color: isSelected
                                        ? AppTheme.primaryTeal
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13.5,
                                      color: isSelected
                                          ? AppTheme.primaryTeal
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Offline Simulation Mode Button
                  IconButton(
                    icon: Icon(
                      isOffline ? Icons.wifi_off : Icons.wifi,
                      color: isOffline
                          ? AppTheme.syncWarning
                          : AppTheme.textSecondary,
                      size: 20,
                    ),
                    tooltip: isOffline
                        ? 'Offline Simulation Mode Active (Tap to switch online)'
                        : 'Simulate Offline Mode (Tap to test offline queue)',
                    onPressed: () async {
                      await ref.read(offlineModeProvider.notifier).toggle();
                      if (context.mounted) {
                        final active = ref.read(offlineModeProvider);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              active
                                  ? 'Offline simulation enabled. Submissions will queue locally.'
                                  : 'Offline simulation disabled. Connected to network.',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 12),

                  // User Profile & Switcher
                  PopupMenuButton<String>(
                    tooltip: 'Account & Demo Switcher',
                    offset: const Offset(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    itemBuilder: (ctx) => [
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.displayName ?? 'Guest User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${currentUser?.studentId ?? "N/A"} • ${currentUser?.role.toUpperCase() ?? "STUDENT"}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Divider(height: 16),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 18,
                              color: AppTheme.primaryTeal,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Switch Demo Profile',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'help',
                        child: Row(
                          children: [
                            Icon(
                              Icons.help_outline,
                              size: 18,
                              color: AppTheme.primaryTeal,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Help & Guidelines',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: AppTheme.statusLost,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.statusLost,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (val) async {
                      if (val == 'switch') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      } else if (val == 'help') {
                        setState(() => _selectedIndex = 4);
                      } else if (val == 'logout') {
                        await ref.read(currentUserProvider.notifier).signOut();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppTheme.primaryTeal,
                            child: Text(
                              currentUser?.displayName.isNotEmpty == true
                                  ? currentUser!.displayName[0]
                                  : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentUser?.displayName ?? 'Account',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Expanded(child: contentWidget),
          ],
        ),
      );
    }

    // Mobile View with Clean Navigation Bar
    return Scaffold(
      body: SafeArea(child: contentWidget),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportItemScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Report Item'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: destinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}
