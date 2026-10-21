import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';
import '../widgets/item_card.dart';
import '../widgets/offline_banner.dart';
import '../widgets/empty_state.dart';
import 'item_details_screen.dart';
import 'report_item_screen.dart';
import 'auth_screen.dart';
import 'welcome_auth_screen.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _searchController = TextEditingController();
  bool _showRecoveryWorkflow = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredItemsProvider);
    final filterState = ref.watch(itemFilterProvider);
    final isOffline = ref.watch(offlineModeProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isDesktop = AppBreakpoints.isDesktop(context);
    final isTablet = AppBreakpoints.isTablet(context);
    final isDark = AppTheme.isDark(context);

    // Quick counts for stats
    final allItems = ref.watch(itemsListProvider);
    final lostCount = allItems.where((i) => i.isLost).length;
    final foundCount = allItems.where((i) => i.isFound).length;
    final returnedCount = allItems.where((i) => i.isReturned).length;

    final isDefaultView =
        filterState.searchQuery.isEmpty &&
        filterState.typeFilter == null &&
        filterState.statusFilter == null &&
        filterState.categoryFilter == 'all';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.desktopContentMaxWidth,
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(itemsListProvider.notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              // Mobile Header Bar (Only visible when not desktop)
              if (!isDesktop)
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.borderColor(context),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
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
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ReFind',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimaryColor(context),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              // Subtitle includes legacy name for widget tests
                              Text(
                                'Finders Keepers? • VIT Campus Lost & Found',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondaryColor(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Offline toggle
                        IconButton(
                          icon: Icon(
                            isOffline ? Icons.wifi_off : Icons.wifi,
                            color: isOffline
                                ? AppTheme.syncWarning
                                : AppTheme.textSecondaryColor(context),
                            size: 20,
                          ),
                          tooltip: isOffline ? 'Offline Active' : 'Online',
                          onPressed: () async {
                            await ref
                                .read(offlineModeProvider.notifier)
                                .toggle();
                          },
                        ),

                        // Profile Icon / Sign in
                        if (currentUser != null)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthScreen(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryIndigo,
                              child: Text(
                                currentUser.displayName.isNotEmpty
                                    ? currentUser.displayName[0]
                                    : 'U',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const WelcomeAuthScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              // Offline Sync Banner
              const SliverToBoxAdapter(child: OfflineBanner()),

              // Search Bar & Filter Controls
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 24 : 16,
                    8,
                    isDesktop ? 24 : 16,
                    8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search items, buildings (SJT, TT, Library), keywords...',
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20,
                              color: AppTheme.textSecondaryColor(context),
                            ),
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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (val) {
                            ref
                                .read(itemFilterProvider.notifier)
                                .setSearchQuery(val);
                          },
                        ),
                      ),
                      if (isDesktop) ...[
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
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
                                MaterialPageRoute(
                                  builder: (_) => const ReportItemScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Report Item'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Quick Type Selector Tabs: All, Lost Items, Found Items
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24 : 16,
                    vertical: 6,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTypeTab(
                          label: 'All Items',
                          count: allItems.length,
                          isSelected:
                              filterState.typeFilter == null &&
                              filterState.statusFilter == null,
                          onTap: () {
                            ref
                                .read(itemFilterProvider.notifier)
                                .resetFilters();
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          label: 'Lost Items',
                          count: lostCount,
                          color: AppTheme.statusLost,
                          isSelected: filterState.typeFilter == ItemType.lost,
                          onTap: () {
                            ref
                                .read(itemFilterProvider.notifier)
                                .setTypeFilter(
                                  filterState.typeFilter == ItemType.lost
                                      ? null
                                      : ItemType.lost,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          label: 'Found Items',
                          count: foundCount,
                          color: AppTheme.statusFound,
                          isSelected: filterState.typeFilter == ItemType.found,
                          onTap: () {
                            ref
                                .read(itemFilterProvider.notifier)
                                .setTypeFilter(
                                  filterState.typeFilter == ItemType.found
                                      ? null
                                      : ItemType.found,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          label: 'Claimed',
                          color: AppTheme.statusClaimed,
                          isSelected:
                              filterState.statusFilter == ItemStatus.claimed,
                          onTap: () {
                            ref
                                .read(itemFilterProvider.notifier)
                                .setStatusFilter(
                                  filterState.statusFilter == ItemStatus.claimed
                                      ? null
                                      : ItemStatus.claimed,
                                );
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildTypeTab(
                          label: 'Returned',
                          color: AppTheme.statusReturned,
                          isSelected:
                              filterState.statusFilter == ItemStatus.returned,
                          onTap: () {
                            ref
                                .read(itemFilterProvider.notifier)
                                .setStatusFilter(
                                  filterState.statusFilter ==
                                          ItemStatus.returned
                                      ? null
                                      : ItemStatus.returned,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Categories Filter Scroll
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                    ),
                    itemCount: CategoryConstants.allCategories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isSelected = filterState.categoryFilter == 'all';
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: const Text('All Categories'),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryIndigo.withValues(
                              alpha: isDark ? 0.25 : 0.12,
                            ),
                            checkmarkColor: AppTheme.primaryIndigoLight,
                            backgroundColor: AppTheme.cardColor(context),
                            side: BorderSide(
                              color: AppTheme.borderColor(context),
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.primaryIndigoLight
                                  : AppTheme.textSecondaryColor(context),
                            ),
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
                          avatar: Icon(
                            cat.icon,
                            size: 14,
                            color: isSelected
                                ? AppTheme.primaryIndigoLight
                                : AppTheme.textSecondaryColor(context),
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryIndigo.withValues(
                            alpha: isDark ? 0.25 : 0.12,
                          ),
                          checkmarkColor: AppTheme.primaryIndigoLight,
                          backgroundColor: AppTheme.cardColor(context),
                          side: BorderSide(
                            color: AppTheme.borderColor(context),
                          ),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primaryIndigoLight
                                : AppTheme.textSecondaryColor(context),
                          ),
                          onSelected: (_) => ref
                              .read(itemFilterProvider.notifier)
                              .setCategoryFilter(isSelected ? 'all' : cat.id),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // --- HERO LANDING SECTION (Displayed on default view) ---
              if (isDefaultView)
                SliverToBoxAdapter(
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      isDesktop ? 24 : 16,
                      isDesktop ? 20 : 14,
                      isDesktop ? 24 : 16,
                      12,
                    ),
                    padding: EdgeInsets.all(isDesktop ? 28 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                            : [
                                const Color(0xFFEEF2FF),
                                const Color(0xFFF8FAFC),
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF312E81)
                            : const Color(0xFFC7D2FE),
                      ),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryIndigo.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.primaryIndigo.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.school,
                                size: 13,
                                color: AppTheme.primaryIndigo,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'VIT Vellore Campus Lost & Found System',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.primaryIndigoLight
                                      : AppTheme.primaryIndigo,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Headline
                        Text(
                          'Never Truly Lost at VIT Vellore',
                          style: TextStyle(
                            fontSize: isDesktop ? 28 : 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimaryColor(context),
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'ReFind securely connects students across SJT, TT, Central Library, and Hostels with verified zero-knowledge item recovery.',
                          style: TextStyle(
                            fontSize: isDesktop ? 14.5 : 13,
                            color: AppTheme.textSecondaryColor(context),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Primary Action Buttons
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.search, size: 18),
                              label: const Text('Report Lost Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.statusLost,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                                    MaterialPageRoute(
                                      builder: (_) => const ReportItemScreen(
                                        initialType: ItemType.lost,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                              ),
                              label: const Text('Report Found Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryIndigo,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
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
                                    MaterialPageRoute(
                                      builder: (_) => const ReportItemScreen(
                                        initialType: ItemType.found,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                            OutlinedButton.icon(
                              icon: Icon(
                                _showRecoveryWorkflow
                                    ? Icons.expand_less
                                    : Icons.info_outline,
                                size: 17,
                              ),
                              label: Text(
                                _showRecoveryWorkflow
                                    ? 'Hide Recovery Process'
                                    : 'How It Works',
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showRecoveryWorkflow =
                                      !_showRecoveryWorkflow;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Real-Time Campus Stats Row
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.borderColor(context),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                'Reported Lost',
                                '$lostCount',
                                AppTheme.statusLost,
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: AppTheme.borderColor(context),
                              ),
                              _buildStatItem(
                                'Reported Found',
                                '$foundCount',
                                AppTheme.statusFound,
                              ),
                              Container(
                                height: 24,
                                width: 1,
                                color: AppTheme.borderColor(context),
                              ),
                              _buildStatItem(
                                'Safely Reunited',
                                '$returnedCount',
                                AppTheme.statusReturned,
                              ),
                            ],
                          ),
                        ),

                        // Collapsible How It Works Explanation
                        if (_showRecoveryWorkflow) ...[
                          const SizedBox(height: 20),
                          Divider(color: AppTheme.borderColor(context)),
                          const SizedBox(height: 12),
                          Text(
                            '4-Step Verified Ownership Recovery',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              _buildWorkflowStepCard(
                                '1. Report & Pin Spot',
                                'Mark building on VIT campus map without exposing private coordinates.',
                                Icons.place_outlined,
                              ),
                              _buildWorkflowStepCard(
                                '2. Secret Challenge',
                                'Finder sets a question only the true owner can answer.',
                                Icons.lock_outline,
                              ),
                              _buildWorkflowStepCard(
                                '3. Private Verification',
                                'Claimant answers are reviewed privately by finder, never broadcasted.',
                                Icons.verified_user_outlined,
                              ),
                              _buildWorkflowStepCard(
                                '4. In-Person OTP',
                                'Dynamic 6-digit salted SHA-256 token verified at physical handover.',
                                Icons.password_outlined,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Item Feed Grid or List
              if (filteredItems.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.search_off,
                    title: 'No Matching Items Found',
                    message: 'Try clearing active filters or searching for different keywords.',
                  ),
                )
              else if (isDesktop || isTablet)
                SliverPadding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 255,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];
                      return ItemCard(
                        item: item,
                        onTap: () => _openItemDetails(item),
                      );
                    }, childCount: filteredItems.length),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ItemCard(
                          item: item,
                          onTap: () => _openItemDetails(item),
                        ),
                      );
                    }, childCount: filteredItems.length),
                  ),
                ),

              // --- FOOTER SECTION ---
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.only(top: 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 28,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    border: Border(
                      top: BorderSide(color: AppTheme.borderColor(context)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryIndigo,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.travel_explore,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ReFind • VIT Vellore',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CodeChef-VIT Promotional Cycle 2026–27 App Development Task',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Built with Flutter, Riverpod, OpenStreetMap & Zero-Knowledge Verification',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMutedColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openItemDetails(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ItemDetailsScreen(item: item)),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflowStepCard(String title, String desc, IconData icon) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.primaryIndigo),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab({
    required String label,
    int? count,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? AppTheme.primaryIndigo;
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: isDark ? 0.2 : 0.12)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : AppTheme.borderColor(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? effectiveColor
                    : AppTheme.textSecondaryColor(context),
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? effectiveColor
                      : (isDark
                            ? AppTheme.surfaceDarkSubtle
                            : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : AppTheme.textSecondaryColor(context),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
