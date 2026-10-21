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
import 'welcome_auth_screen.dart';

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
    final outboxCount = ref.watch(outboxCountProvider);
    final isDark = AppTheme.isDark(context);

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

    // --- DESKTOP VIEW WITH EXPANDED HEADER ---
    if (isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            // Desktop Header Bar
            Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor(context)),
                ),
                boxShadow: isDark
                    ? AppTheme.darkSubtleShadow
                    : AppTheme.subtleCardShadow,
              ),
              child: Row(
                children: [
                  // App Brand
                  InkWell(
                    onTap: () => setState(() => _selectedIndex = 0),
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryIndigo,
                                AppTheme.primaryIndigoLight,
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
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'ReFind',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimaryColor(context),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryIndigo.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VIT Vellore',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryIndigo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Finders Keepers? • Campus Lost & Found',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 32),

                  // Desktop Navigation Tabs
                  Expanded(
                    child: Row(
                      children: List.generate(destinations.length, (index) {
                        final item = destinations[index];
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => setState(() => _selectedIndex = index),
                            borderRadius: BorderRadius.circular(10),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryIndigo.withValues(
                                        alpha: isDark ? 0.2 : 0.08,
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
                                        ? AppTheme.primaryIndigoLight
                                        : AppTheme.textSecondaryColor(context),
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
                                          ? AppTheme.primaryIndigoLight
                                          : AppTheme.textSecondaryColor(
                                              context,
                                            ),
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

                  // Outbox Queue Indicator (if items waiting)
                  if (outboxCount > 0) ...[
                    ActionChip(
                      avatar: const Icon(
                        Icons.sync_problem,
                        size: 16,
                        color: AppTheme.syncWarning,
                      ),
                      label: Text('$outboxCount Queued'),
                      labelStyle: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.syncWarning,
                      ),
                      backgroundColor: AppTheme.syncWarningBg,
                      side: const BorderSide(color: AppTheme.syncWarningBorder),
                      onPressed: () async {
                        final synced = await ref
                            .read(itemsListProvider.notifier)
                            .syncOfflineQueue();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppTheme.statusReturned,
                              content: Text(
                                'Synced $synced queued item(s) to server.',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Offline Simulation Mode Button
                  IconButton(
                    icon: Icon(
                      isOffline ? Icons.wifi_off : Icons.wifi,
                      color: isOffline
                          ? AppTheme.syncWarning
                          : AppTheme.textSecondaryColor(context),
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
                  const SizedBox(width: 6),

                  // Sun / Moon Theme Toggle Button
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark
                          ? AppTheme.accentAmber
                          : AppTheme.textSecondaryColor(context),
                      size: 20,
                    ),
                    tooltip: isDark
                        ? 'Switch to Light Theme'
                        : 'Switch to Dark Theme',
                    onPressed: () => ref
                        .read(themeModeProvider.notifier)
                        .toggleTheme(context),
                  ),
                  const SizedBox(width: 12),

                  // User Profile & Switcher OR Sign In Button
                  if (currentUser != null)
                    PopupMenuButton<String>(
                      tooltip: 'Account & Demo Switcher',
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      color: AppTheme.cardColor(context),
                      itemBuilder: (ctx) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                              Text(
                                '${currentUser.studentId} • ${currentUser.role.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryColor(context),
                                ),
                              ),
                              Divider(
                                height: 16,
                                color: AppTheme.borderColor(context),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'switch',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.swap_horiz,
                                size: 18,
                                color: AppTheme.primaryIndigo,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Switch Demo Profile',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'help',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.help_outline,
                                size: 18,
                                color: AppTheme.primaryIndigo,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Help & Guidelines',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textPrimaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: const Row(
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
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        } else if (val == 'help') {
                          setState(() => _selectedIndex = 4);
                        } else if (val == 'logout') {
                          await ref
                              .read(currentUserProvider.notifier)
                              .signOut();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtleColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderColor(context),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.primaryIndigo,
                              child: Text(
                                currentUser.displayName.isNotEmpty
                                    ? currentUser.displayName[0]
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
                              currentUser.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      icon: const Icon(Icons.login, size: 16),
                      label: const Text(
                        'Sign In / Register',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WelcomeAuthScreen(),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Main Desktop Content Area
            Expanded(child: contentWidget),
          ],
        ),
      );
    }

    // --- MOBILE VIEW WITH CLEAN RESPONSIVE BOTTOM NAVIGATION ---
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryIndigo, AppTheme.primaryIndigoLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.travel_explore,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ReFind: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimaryColor(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Finders Keepers?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                Text(
                  'VIT Campus Lost & Found',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Sun / Moon Theme Toggle in Mobile Header
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark
                  ? AppTheme.accentAmber
                  : AppTheme.textSecondaryColor(context),
              size: 20,
            ),
            tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
            onPressed: () =>
                ref.read(themeModeProvider.notifier).toggleTheme(context),
          ),
          // User / Switcher Button in Mobile Header
          if (currentUser != null)
            IconButton(
              icon: CircleAvatar(
                radius: 13,
                backgroundColor: AppTheme.primaryIndigo,
                child: Text(
                  currentUser.displayName.isNotEmpty
                      ? currentUser.displayName[0]
                      : 'U',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              tooltip: 'Account Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
            )
          else
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
                );
              },
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(child: contentWidget),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                if (currentUser == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WelcomeAuthScreen(),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportItemScreen()),
                  );
                }
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
