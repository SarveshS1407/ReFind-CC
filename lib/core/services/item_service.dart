import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../models/sync_task.dart';
import '../utils/formatters.dart';
import 'local_storage_service.dart';

class ItemService {
  final LocalStorageService _storage;
  List<ItemModel> _items = [];

  ItemService(this._storage) {
    _loadInitialItems();
  }

  void _loadInitialItems() {
    final cached = _storage.getItems();
    if (cached.isNotEmpty) {
      _items = cached;
    } else {
      _items = _generateSeedItems();
      _storage.saveItems(_items);
    }
  }

  List<ItemModel> get allItems => List.unmodifiable(_items);

  /// Retrieves an item by its unique ID
  ItemModel? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filters and searches items
  List<ItemModel> getFilteredItems({
    String query = '',
    ItemType? typeFilter,
    ItemStatus? statusFilter,
    String? categoryFilter,
    String? locationIdFilter,
  }) {
    return _items.where((item) {
      // Type filter
      if (typeFilter != null && item.type != typeFilter) return false;

      // Status filter
      if (statusFilter != null && item.status != statusFilter) return false;

      // Category filter
      if (categoryFilter != null &&
          categoryFilter.isNotEmpty &&
          categoryFilter != 'all' &&
          item.category != categoryFilter) {
        return false;
      }

      // Location filter
      if (locationIdFilter != null &&
          locationIdFilter.isNotEmpty &&
          locationIdFilter != 'all' &&
          item.campusLocationId != locationIdFilter) {
        return false;
      }

      // Search query (matches title, description, or campus building)
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final inTitle = item.title.toLowerCase().contains(q);
        final inDesc = item.description.toLowerCase().contains(q);
        final inLoc = item.campusLocationName.toLowerCase().contains(q);
        if (!inTitle && !inDesc && !inLoc) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Submits a newly reported lost or found item.
  /// If simulated offline or disconnected, queues locally in the outbox.
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
    final isOffline = _storage.isSimulatedOffline();
    final now = DateTime.now();

    final newItem = ItemModel(
      id: 'itm_${const Uuid().v4().substring(0, 8)}',
      title: title.trim(),
      description: description.trim(),
      category: category,
      type: type,
      status: type == ItemType.lost ? ItemStatus.lost : ItemStatus.found,
      campusLocationId: campusLocationId,
      campusLocationName: campusLocationName,
      latitude: latitude,
      longitude: longitude,
      isApproximateLocation: true,
      reporterId: reporterId,
      reporterName: reporterName,
      reporterContact: reporterContact,
      imageUrl: imageUrl,
      dateReported: dateReported ?? now,
      rewardAmount: rewardAmount,
      verificationQuestion: verificationQuestion,
      secretAnswerHash: secretAnswerHash,
      syncStatus: isOffline ? SyncStatus.queuedLocally : SyncStatus.synced,
      createdAt: now,
      updatedAt: now,
    );

    _items.insert(0, newItem);
    await _storage.saveItems(_items);

    if (isOffline) {
      // Add to offline sync outbox
      final task = OfflineSyncTask(
        id: 'task_${const Uuid().v4().substring(0, 8)}',
        type: 'create_item',
        payload: newItem.toMap(),
        createdAt: now,
        status: SyncTaskStatus.pending,
      );
      await _storage.addOutboxTask(task);
    }

    return newItem;
  }

  /// Updates an item
  Future<void> updateItem(ItemModel updatedItem) async {
    final index = _items.indexWhere((i) => i.id == updatedItem.id);
    if (index != -1) {
      _items[index] = updatedItem;
      await _storage.saveItems(_items);
    }
  }

  /// Syncs all queued offline tasks
  Future<int> syncOfflineTasks() async {
    final tasks = _storage.getOutboxTasks();
    if (tasks.isEmpty) return 0;

    int syncedCount = 0;
    final remainingTasks = <OfflineSyncTask>[];

    for (final task in tasks) {
      try {
        if (task.type == 'create_item') {
          final itemId = task.payload['id'];
          final index = _items.indexWhere((i) => i.id == itemId);
          if (index != -1) {
            _items[index] = _items[index].copyWith(
              syncStatus: SyncStatus.synced,
              syncError: null,
            );
          }
        }
        syncedCount++;
      } catch (e) {
        remainingTasks.add(task.copyWith(
          retryCount: task.retryCount + 1,
          lastError: e.toString(),
          status: SyncTaskStatus.failed,
        ));
      }
    }

    await _storage.saveOutboxTasks(remainingTasks);
    await _storage.saveItems(_items);
    return syncedCount;
  }

  /// Recommendations engine: Finds counterpart items that match by category, keyword similarity, and distance
  List<ItemMatchRecommendation> findPotentialMatches(ItemModel target) {
    final counterpartType =
        target.isLost ? ItemType.found : ItemType.lost;
    final candidates = _items
        .where((i) => i.type == counterpartType && i.id != target.id)
        .toList();

    final recommendations = <ItemMatchRecommendation>[];

    for (final candidate in candidates) {
      double score = 0.0;

      // 1. Category match (+40 points)
      if (candidate.category == target.category) {
        score += 0.40;
      }

      // 2. Text similarity (+35 points)
      final textSim = Formatters.computeTextSimilarity(
        '${target.title} ${target.description}',
        '${candidate.title} ${candidate.description}',
      );
      score += textSim * 0.35;

      // 3. Proximity bonus (+25 points if within same building / 250m)
      final distance = Formatters.calculateDistanceMeters(
        target.latitude,
        target.longitude,
        candidate.latitude,
        candidate.longitude,
      );
      if (distance < 300) {
        score += 0.25;
      } else if (distance < 700) {
        score += 0.12;
      }

      if (score >= 0.30) {
        recommendations.add(
          ItemMatchRecommendation(
            matchedItem: candidate,
            confidenceScore: score.clamp(0.0, 1.0),
            reason: _explainMatchReason(target, candidate, distance),
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return recommendations;
  }

  String _explainMatchReason(ItemModel a, ItemModel b, double distance) {
    final reasons = <String>[];
    if (a.category == b.category) {
      reasons.add('Same category');
    }
    if (distance < 300) {
      reasons.add('Found within ${distance.round()}m (${b.campusLocationName})');
    }
    return reasons.join(' • ');
  }

  // --- Seed Data for Campus ---
  static List<ItemModel> _generateSeedItems() {
    final now = DateTime.now();
    return [
      ItemModel(
        id: 'itm_01',
        title: 'Apple AirPods Pro (2nd Gen) in White Case',
        description:
            'Found an AirPods Pro 2 case near the Food Mall outdoor gazebo table. Has a slight scratch on the hinge and a blue silicone lanyard attached.',
        category: 'audio',
        type: ItemType.found,
        status: ItemStatus.found,
        campusLocationId: 'food_mall',
        campusLocationName: 'Food Mall & Gazebo',
        latitude: 12.9695,
        longitude: 79.1560,
        isApproximateLocation: true,
        reporterId: 'usr_diya_02',
        reporterName: 'Diya Patel',
        reporterContact: 'diya.patel2023@vitstudent.ac.in',
        dateReported: now.subtract(const Duration(hours: 3)),
        verificationQuestion:
            'What custom initials or engraving is on the back, or what exact color is the inner lanyard loop?',
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      ItemModel(
        id: 'itm_02',
        title: 'VIT Student ID Card & Library RFID Badge',
        description:
            'Lost my student ID card with lanyard somewhere between SJT 6th floor lab and TT ground floor. Need it urgently for upcoming lab exams!',
        category: 'id_cards',
        type: ItemType.lost,
        status: ItemStatus.lost,
        campusLocationId: 'sjt',
        campusLocationName: 'Silver Jubilee Tower (SJT)',
        latitude: 12.9712,
        longitude: 79.1593,
        isApproximateLocation: true,
        reporterId: 'usr_aarav_01',
        reporterName: 'Aarav Sharma',
        reporterContact: '+91 98765 43210',
        rewardAmount: 200,
        dateReported: now.subtract(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      ItemModel(
        id: 'itm_03',
        title: 'Set of 3 Keys on Spider-Man Metal Keychain',
        description:
            'Found 3 silver keys on a Spider-Man metal ring on a bench in front of Technology Tower (TT). One key has a yellow tape wrap.',
        category: 'keys',
        type: ItemType.found,
        status: ItemStatus.found,
        campusLocationId: 'tt',
        campusLocationName: 'Technology Tower (TT)',
        latitude: 12.9701,
        longitude: 79.1578,
        isApproximateLocation: true,
        reporterId: 'usr_moderator_03',
        reporterName: 'Prof. R. Verma (Campus Security)',
        reporterContact: 'security.warden@vit.ac.in',
        dateReported: now.subtract(const Duration(days: 1)),
        verificationQuestion:
            'What number or letter code is stamped on the largest room key?',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ItemModel(
        id: 'itm_04',
        title: 'Casio fx-991CW ClassWiz Scientific Calculator',
        description:
            'Left behind my calculator in Central Library 2nd floor silent study room. Black color with my name written in pencil inside the slide-on cover.',
        category: 'books_notes',
        type: ItemType.lost,
        status: ItemStatus.lost,
        campusLocationId: 'lib',
        campusLocationName: 'Central Library (Periyar EVR)',
        latitude: 12.9692,
        longitude: 79.1565,
        isApproximateLocation: true,
        reporterId: 'usr_aarav_01',
        reporterName: 'Aarav Sharma',
        reporterContact: 'aarav.sharma2023@vitstudent.ac.in',
        rewardAmount: 150,
        dateReported: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      ItemModel(
        id: 'itm_05',
        title: 'Brown Leather Bi-Fold Wallet',
        description:
            'Found a brown Tommy Hilfiger wallet near the outdoor stadium basketball court bleachers. Safely deposited at security desk.',
        category: 'wallets',
        type: ItemType.found,
        status: ItemStatus.found,
        campusLocationId: 'sports_complex',
        campusLocationName: 'Outdoor Stadium & Sports Complex',
        latitude: 12.9730,
        longitude: 79.1580,
        isApproximateLocation: true,
        reporterId: 'usr_moderator_03',
        reporterName: 'Prof. R. Verma (Campus Security)',
        reporterContact: 'security.warden@vit.ac.in',
        dateReported: now.subtract(const Duration(days: 2)),
        verificationQuestion:
            'State the name on any debit card or describe the currency bills inside.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}

class ItemMatchRecommendation {
  final ItemModel matchedItem;
  final double confidenceScore;
  final String reason;

  const ItemMatchRecommendation({
    required this.matchedItem,
    required this.confidenceScore,
    required this.reason,
  });
}
