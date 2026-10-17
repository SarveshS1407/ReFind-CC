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

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _searchController = TextEditingController();

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

    // Quick counts for stats
    final allItems = ref.watch(itemsListProvider);
    final lostCount = allItems.where((i) => i.isLost).length;
    final foundCount = allItems.where((i) => i.isFound).length;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.desktopContentMaxWidth,
        ),
        child: Column(
          children: [
            // Mobile App Bar Header (Only shown on mobile, desktop header is in ResponsiveMainScreen)
            if (!isDesktop)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.cardBorder),
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
                            AppTheme.primaryTeal,
                            AppTheme.primaryTealLight,
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finders Keepers?',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Text(
                            'VIT Campus Lost & Found',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Offline simulation toggle
                    IconButton(
                      icon: Icon(
                        isOffline ? Icons.wifi_off : Icons.wifi,
                        color: isOffline
                            ? AppTheme.syncWarning
                            : AppTheme.textSecondary,
                        size: 20,
                      ),
                      tooltip: isOffline ? 'Offline Active' : 'Online',
                      onPressed: () async {
                        await ref.read(offlineModeProvider.notifier).toggle();
                      },
                    ),

                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppTheme.primaryTeal,
                        child: Text(
                          currentUser?.displayName.isNotEmpty == true
                              ? currentUser!.displayName[0]
                              : 'U',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Offline Sync Banner
            const OfflineBanner(),

            // Search Bar & Stats Header
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 16,
                isDesktop ? 20 : 12,
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
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 20,
                          color: AppTheme.textSecondary,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportItemScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Report New Item'),
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

            // Quick Type Selector Tabs: All, Lost Items, Found Items
            Padding(
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
                        ref.read(itemFilterProvider.notifier).resetFilters();
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
                              filterState.statusFilter == ItemStatus.returned
                                  ? null
                                  : ItemStatus.returned,
                            );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Categories Filter Scroll
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
                itemCount: CategoryConstants.allCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isSelected = filterState.categoryFilter == 'all';
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: const Text('All Categories'),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryTeal.withValues(
                          alpha: 0.12,
                        ),
                        checkmarkColor: AppTheme.primaryTeal,
                        labelStyle: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : AppTheme.textSecondary,
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
                            ? AppTheme.primaryTeal
                            : AppTheme.textSecondary,
                      ),
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppTheme.primaryTeal.withValues(
                        alpha: 0.12,
                      ),
                      checkmarkColor: AppTheme.primaryTeal,
                      labelStyle: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : AppTheme.textSecondary,
                      ),
                      onSelected: (_) => ref
                          .read(itemFilterProvider.notifier)
                          .setCategoryFilter(isSelected ? 'all' : cat.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),

            // Item Feed (Responsive Grid on Desktop / Tablet, List on Mobile)
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.read(itemsListProvider.notifier).refresh();
                },
                child: filteredItems.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'No Matching Items Found',
                        message: 'Try clearing active filters or searching for different keywords.',
                      )
                    : isDesktop || isTablet
                    ? GridView.builder(
                        padding: EdgeInsets.all(isDesktop ? 24 : 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 245,
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ItemCard(
                            item: item,
                            onTap: () => _openItemDetails(item),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ItemCard(
                            item: item,
                            onTap: () => _openItemDetails(item),
                          );
                        },
                      ),
              ),
            ),
          ],
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

  Widget _buildTypeTab({
    required String label,
    int? count,
    Color? color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? AppTheme.primaryTeal;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveColor : AppTheme.cardBorder,
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
                color: isSelected ? effectiveColor : AppTheme.textSecondary,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? effectiveColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
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
