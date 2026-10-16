import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';
import '../widgets/item_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/empty_state.dart';
import 'report_item_screen.dart';
import 'item_details_screen.dart';
import 'map_screen.dart';
import 'my_activity_screen.dart';
import 'moderation_screen.dart';
import 'auth_screen.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isModerator = currentUser?.isModerator ?? false;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.feed_outlined),
        selectedIcon: Icon(Icons.feed),
        label: 'Feed',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Map',
      ),
      const NavigationDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: 'Activity',
      ),
      if (isModerator)
        const NavigationDestination(
          icon: Icon(Icons.security_outlined),
          selectedIcon: Icon(Icons.security),
          label: 'Moderation',
        )
      else
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
    ];

    Widget bodyWidget;
    switch (_currentIndex) {
      case 0:
        bodyWidget = _buildFeedTab();
        break;
      case 1:
        bodyWidget = const MapScreen();
        break;
      case 2:
        bodyWidget = const MyActivityScreen();
        break;
      case 3:
        bodyWidget = isModerator
            ? const ModerationScreen()
            : _buildProfileTab();
        break;
      default:
        bodyWidget = _buildFeedTab();
    }

    return Scaffold(
      body: SafeArea(child: bodyWidget),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: destinations,
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Report Item'),
            )
          : null,
    );
  }

  Widget _buildFeedTab() {
    final filteredItems = ref.watch(filteredItemsProvider);
    final filterState = ref.watch(itemFilterProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        // Top App Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.travel_explore,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finders Keepers?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'VIT Campus Lost & Found',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Offline Simulation Mode Toggle
              IconButton(
                icon: Icon(
                  isOffline ? Icons.wifi_off : Icons.wifi,
                  color: isOffline ? AppTheme.syncWarning : Colors.grey.shade600,
                  size: 20,
                ),
                tooltip: isOffline
                    ? 'Offline Simulation Active (Tap to disable)'
                    : 'Simulate Offline Mode (Tap to test outbox)',
                onPressed: () async {
                  await ref.read(offlineModeProvider.notifier).toggle();
                  if (mounted) {
                    final active = ref.read(offlineModeProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(active
                            ? 'Offline simulation enabled. Submissions will queue locally.'
                            : 'Offline simulation disabled. Reconnected to live network.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),

              // User Profile Avatar / Switcher
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  );
                },
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  child: Text(
                    currentUser?.displayName.isNotEmpty == true
                        ? currentUser!.displayName[0]
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Offline Banner
        const OfflineBanner(),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items, buildings, keywords...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(itemFilterProvider.notifier)
                            .setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (val) {
              ref.read(itemFilterProvider.notifier).setSearchQuery(val);
            },
          ),
        ),

        // Filter Chips (Type Filter)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildTypeChip('All Items', null, filterState.typeFilter == null),
              const SizedBox(width: 8),
              _buildTypeChip('Lost Items', ItemType.lost,
                  filterState.typeFilter == ItemType.lost),
              const SizedBox(width: 8),
              _buildTypeChip('Found Items', ItemType.found,
                  filterState.typeFilter == ItemType.found),
              const SizedBox(width: 8),
              _buildStatusChip('Claimed', ItemStatus.claimed,
                  filterState.statusFilter == ItemStatus.claimed),
              const SizedBox(width: 8),
              _buildStatusChip('Returned', ItemStatus.returned,
                  filterState.statusFilter == ItemStatus.returned),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Categories Scroll
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: CategoryConstants.allCategories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = filterState.categoryFilter == 'all';
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('All Categories'),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(itemFilterProvider.notifier)
                        .setCategoryFilter('all'),
                  ),
                );
              }
              final cat = CategoryConstants.allCategories[index - 1];
              final isSelected = filterState.categoryFilter == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: Icon(cat.icon, size: 14),
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (_) => ref
                      .read(itemFilterProvider.notifier)
                      .setCategoryFilter(isSelected ? 'all' : cat.id),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // Feed List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.read(itemsListProvider.notifier).refresh();
            },
            child: filteredItems.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'No Matching Items Found',
                    message:
                        'Try clearing filters or search with a different keyword.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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
          ),
        ),
      ],
    );
  }

  Widget _buildTypeChip(String label, ItemType? type, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(itemFilterProvider.notifier).setTypeFilter(type);
      },
    );
  }

  Widget _buildStatusChip(String label, ItemStatus status, bool isSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(itemFilterProvider.notifier).setStatusFilter(
              isSelected ? null : status,
            );
      },
    );
  }

  Widget _buildProfileTab() {
    final currentUser = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryBlue,
                child: Text(
                  currentUser?.displayName.isNotEmpty == true
                      ? currentUser!.displayName[0]
                      : 'U',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                currentUser?.displayName ?? 'Guest User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reg No: ${currentUser?.studentId ?? "N/A"} • Role: ${currentUser?.role.toUpperCase() ?? "STUDENT"}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                currentUser?.email ?? '',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          icon: const Icon(Icons.swap_horiz),
          label: const Text('Switch Demo Profile (Evaluator Quick-Access)'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Sign Out'),
          onPressed: () async {
            await ref.read(currentUserProvider.notifier).signOut();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            }
          },
        ),
      ],
    );
  }
}
