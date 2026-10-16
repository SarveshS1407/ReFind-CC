import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/user_model.dart';
import '../core/models/item_model.dart';
import '../core/models/claim_model.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/auth_service.dart';
import '../core/services/item_service.dart';
import '../core/services/claim_service.dart';

// Services
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError('Initialize localStorageServiceProvider in main');
});

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return AuthService(storage);
});

final itemServiceProvider = Provider<ItemService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ItemService(storage);
});

final claimServiceProvider = Provider<ClaimService>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  final itemService = ref.watch(itemServiceProvider);
  return ClaimService(storage, itemService);
});

// Current User State (Riverpod 3 Notifier)
class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    return ref.watch(authServiceProvider).currentUser;
  }

  Future<void> signIn(String email, String password) async {
    final user = await ref.read(authServiceProvider).signInWithEmail(
          email: email,
          password: password,
        );
    state = user;
  }

  Future<void> register(
    String name,
    String email,
    String studentId,
    String? phone,
  ) async {
    final user = await ref.read(authServiceProvider).registerStudent(
          name: name,
          email: email,
          studentId: studentId,
          phone: phone,
        );
    state = user;
  }

  Future<void> switchProfile(AppUser user) async {
    await ref.read(authServiceProvider).switchProfile(user);
    state = user;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = null;
  }
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, AppUser?>(CurrentUserNotifier.new);

// Offline Mode Notifier
class OfflineModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(localStorageServiceProvider).isSimulatedOffline();
  }

  Future<void> toggle() async {
    final storage = ref.read(localStorageServiceProvider);
    final newValue = !state;
    await storage.setSimulatedOffline(newValue);
    state = newValue;
  }
}

final offlineModeProvider =
    NotifierProvider<OfflineModeNotifier, bool>(OfflineModeNotifier.new);

// Outbox Count Provider
final outboxCountProvider = Provider<int>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  ref.watch(itemsListProvider); // Trigger re-calculation
  return storage.getOutboxTasks().length;
});

// Filter State Model
class ItemFilterState {
  final String searchQuery;
  final ItemType? typeFilter;
  final ItemStatus? statusFilter;
  final String categoryFilter;
  final String locationIdFilter;

  const ItemFilterState({
    this.searchQuery = '',
    this.typeFilter,
    this.statusFilter,
    this.categoryFilter = 'all',
    this.locationIdFilter = 'all',
  });

  ItemFilterState copyWith({
    String? searchQuery,
    ItemType? typeFilter,
    ItemStatus? statusFilter,
    String? categoryFilter,
    String? locationIdFilter,
    bool clearType = false,
    bool clearStatus = false,
  }) {
    return ItemFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      categoryFilter: categoryFilter ?? this.categoryFilter,
      locationIdFilter: locationIdFilter ?? this.locationIdFilter,
    );
  }
}

class ItemFilterNotifier extends Notifier<ItemFilterState> {
  @override
  ItemFilterState build() => const ItemFilterState();

  void setSearchQuery(String q) => state = state.copyWith(searchQuery: q);
  void setTypeFilter(ItemType? type) =>
      state = state.copyWith(typeFilter: type, clearType: type == null);
  void setStatusFilter(ItemStatus? status) =>
      state = state.copyWith(statusFilter: status, clearStatus: status == null);
  void setCategoryFilter(String cat) =>
      state = state.copyWith(categoryFilter: cat);
  void setLocationFilter(String loc) =>
      state = state.copyWith(locationIdFilter: loc);
  void resetFilters() => state = const ItemFilterState();
}

final itemFilterProvider =
    NotifierProvider<ItemFilterNotifier, ItemFilterState>(ItemFilterNotifier.new);

// Items List Notifier
class ItemsListNotifier extends Notifier<List<ItemModel>> {
  @override
  List<ItemModel> build() {
    return ref.watch(itemServiceProvider).allItems;
  }

  void refresh() {
    state = ref.read(itemServiceProvider).allItems;
  }

  Future<ItemModel> reportItem({
    required String title,
    required String description,
    required String category,
    required ItemType type,
    required String campusLocationId,
    required String campusLocationName,
    required double latitude,
    required double longitude,
    required String reporterId,
    required String reporterName,
    String? reporterContact,
    String? imageUrl,
    DateTime? dateReported,
    double? rewardAmount,
    String? verificationQuestion,
    String? secretAnswerHash,
  }) async {
    final newItem = await ref.read(itemServiceProvider).reportItem(
          title: title,
          description: description,
          category: category,
          type: type,
          campusLocationId: campusLocationId,
          campusLocationName: campusLocationName,
          latitude: latitude,
          longitude: longitude,
          reporterId: reporterId,
          reporterName: reporterName,
          reporterContact: reporterContact,
          imageUrl: imageUrl,
          dateReported: dateReported,
          rewardAmount: rewardAmount,
          verificationQuestion: verificationQuestion,
          secretAnswerHash: secretAnswerHash,
        );
    state = ref.read(itemServiceProvider).allItems;
    return newItem;
  }

  Future<int> syncOfflineQueue() async {
    final count = await ref.read(itemServiceProvider).syncOfflineTasks();
    state = ref.read(itemServiceProvider).allItems;
    return count;
  }
}

final itemsListProvider =
    NotifierProvider<ItemsListNotifier, List<ItemModel>>(ItemsListNotifier.new);

// Filtered Items Computed Provider
final filteredItemsProvider = Provider<List<ItemModel>>((ref) {
  final items = ref.watch(itemsListProvider);
  final filter = ref.watch(itemFilterProvider);

  return items.where((item) {
    // Type filter
    if (filter.typeFilter != null && item.type != filter.typeFilter) {
      return false;
    }

    // Status filter
    if (filter.statusFilter != null && item.status != filter.statusFilter) {
      return false;
    }

    // Category filter
    if (filter.categoryFilter != 'all' &&
        item.category != filter.categoryFilter) {
      return false;
    }

    // Location filter
    if (filter.locationIdFilter != 'all' &&
        item.campusLocationId != filter.locationIdFilter) {
      return false;
    }

    // Search query
    if (filter.searchQuery.trim().isNotEmpty) {
      final q = filter.searchQuery.trim().toLowerCase();
      final inTitle = item.title.toLowerCase().contains(q);
      final inDesc = item.description.toLowerCase().contains(q);
      final inLoc = item.campusLocationName.toLowerCase().contains(q);
      if (!inTitle && !inDesc && !inLoc) return false;
    }

    return true;
  }).toList();
});

// Claims Notifier
class ClaimsNotifier extends Notifier<List<ClaimModel>> {
  @override
  List<ClaimModel> build() {
    return ref.watch(claimServiceProvider).allClaims;
  }

  void refresh() {
    state = ref.read(claimServiceProvider).allClaims;
  }

  Future<ClaimModel> submitClaim({
    required String itemId,
    required AppUser claimant,
    required String proofDescription,
    required String answerToQuestion,
    String? proofImageUrl,
  }) async {
    final claim = await ref.read(claimServiceProvider).submitClaim(
          itemId: itemId,
          claimant: claimant,
          proofDescription: proofDescription,
          answerToQuestion: answerToQuestion,
          proofImageUrl: proofImageUrl,
        );
    state = ref.read(claimServiceProvider).allClaims;
    ref.read(itemsListProvider.notifier).refresh();
    return claim;
  }

  Future<void> approveClaim({
    required String claimId,
    required AppUser reviewer,
  }) async {
    await ref.read(claimServiceProvider).approveClaim(
          claimId: claimId,
          reviewer: reviewer,
        );
    state = ref.read(claimServiceProvider).allClaims;
    ref.read(itemsListProvider.notifier).refresh();
  }

  Future<void> rejectClaim({
    required String claimId,
    required AppUser reviewer,
    required String reason,
  }) async {
    await ref.read(claimServiceProvider).rejectClaim(
          claimId: claimId,
          reviewer: reviewer,
          reason: reason,
        );
    state = ref.read(claimServiceProvider).allClaims;
    ref.read(itemsListProvider.notifier).refresh();
  }

  Future<bool> verifyHandover({
    required String itemId,
    required String enteredOtp,
    required AppUser reviewer,
  }) async {
    final result = await ref.read(claimServiceProvider).verifyAndCompleteHandover(
          itemId: itemId,
          enteredOtp: enteredOtp,
          reviewer: reviewer,
        );
    state = ref.read(claimServiceProvider).allClaims;
    ref.read(itemsListProvider.notifier).refresh();
    return result;
  }
}

final claimsProvider =
    NotifierProvider<ClaimsNotifier, List<ClaimModel>>(ClaimsNotifier.new);
