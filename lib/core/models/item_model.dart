enum ItemType { lost, found }

enum ItemStatus { lost, found, claimed, returned, cancelled }

enum SyncStatus { synced, queuedLocally, syncError }

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final ItemType type;
  final ItemStatus status;
  final String campusLocationId;
  final String campusLocationName;
  final double latitude;
  final double longitude;
  final bool isApproximateLocation;
  final String reporterId;
  final String reporterName;
  final String? reporterContact; // Hidden from general public
  final String? imageUrl;
  final DateTime dateReported;
  final double? rewardAmount;

  // Ownership Verification Fields
  // For Found Items: A non-public challenge question set by finder
  // (e.g. "What sticker is on the back?", "What is the initials engraved?")
  final String? verificationQuestion;
  // Optional SHA-256 hash of answer if finder wants auto-matching, else reviewed manually
  final String? secretAnswerHash;

  // Handover state
  final String? acceptedClaimId;
  final String? handoverCodeHash; // Salted SHA-256 hash of the 6-digit OTP
  final DateTime? handoverCompletedAt;

  // Offline / Sync status
  final SyncStatus syncStatus;
  final String? syncError;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.type,
    required this.status,
    required this.campusLocationId,
    required this.campusLocationName,
    required this.latitude,
    required this.longitude,
    this.isApproximateLocation = true,
    required this.reporterId,
    required this.reporterName,
    this.reporterContact,
    this.imageUrl,
    required this.dateReported,
    this.rewardAmount,
    this.verificationQuestion,
    this.secretAnswerHash,
    this.acceptedClaimId,
    this.handoverCodeHash,
    this.handoverCompletedAt,
    this.syncStatus = SyncStatus.synced,
    this.syncError,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLost => type == ItemType.lost;
  bool get isFound => type == ItemType.found;
  bool get isClaimed => status == ItemStatus.claimed;
  bool get isReturned => status == ItemStatus.returned;
  bool get isPendingSync => syncStatus == SyncStatus.queuedLocally;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'type': type.name,
      'status': status.name,
      'campusLocationId': campusLocationId,
      'campusLocationName': campusLocationName,
      'latitude': latitude,
      'longitude': longitude,
      'isApproximateLocation': isApproximateLocation,
      'reporterId': reporterId,
      'reporterName': reporterName,
      'reporterContact': reporterContact,
      'imageUrl': imageUrl,
      'dateReported': dateReported.toIso8601String(),
      'rewardAmount': rewardAmount,
      'verificationQuestion': verificationQuestion,
      'secretAnswerHash': secretAnswerHash,
      'acceptedClaimId': acceptedClaimId,
      'handoverCodeHash': handoverCodeHash,
      'handoverCompletedAt': handoverCompletedAt?.toIso8601String(),
      'syncStatus': syncStatus.name,
      'syncError': syncError,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      type: ItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ItemType.lost,
      ),
      status: ItemStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ItemStatus.lost,
      ),
      campusLocationId: map['campusLocationId'] ?? 'sjt',
      campusLocationName: map['campusLocationName'] ?? 'Campus',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 12.9698,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 79.1559,
      isApproximateLocation: map['isApproximateLocation'] ?? true,
      reporterId: map['reporterId'] ?? '',
      reporterName: map['reporterName'] ?? 'Student',
      reporterContact: map['reporterContact'],
      imageUrl: map['imageUrl'],
      dateReported: map['dateReported'] != null
          ? DateTime.parse(map['dateReported'])
          : DateTime.now(),
      rewardAmount: (map['rewardAmount'] as num?)?.toDouble(),
      verificationQuestion: map['verificationQuestion'],
      secretAnswerHash: map['secretAnswerHash'],
      acceptedClaimId: map['acceptedClaimId'],
      handoverCodeHash: map['handoverCodeHash'],
      handoverCompletedAt: map['handoverCompletedAt'] != null
          ? DateTime.parse(map['handoverCompletedAt'])
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == map['syncStatus'],
        orElse: () => SyncStatus.synced,
      ),
      syncError: map['syncError'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  ItemModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    ItemType? type,
    ItemStatus? status,
    String? campusLocationId,
    String? campusLocationName,
    double? latitude,
    double? longitude,
    bool? isApproximateLocation,
    String? reporterId,
    String? reporterName,
    String? reporterContact,
    String? imageUrl,
    DateTime? dateReported,
    double? rewardAmount,
    String? verificationQuestion,
    String? secretAnswerHash,
    String? acceptedClaimId,
    String? handoverCodeHash,
    DateTime? handoverCompletedAt,
    SyncStatus? syncStatus,
    String? syncError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      type: type ?? this.type,
      status: status ?? this.status,
      campusLocationId: campusLocationId ?? this.campusLocationId,
      campusLocationName: campusLocationName ?? this.campusLocationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isApproximateLocation:
          isApproximateLocation ?? this.isApproximateLocation,
      reporterId: reporterId ?? this.reporterId,
      reporterName: reporterName ?? this.reporterName,
      reporterContact: reporterContact ?? this.reporterContact,
      imageUrl: imageUrl ?? this.imageUrl,
      dateReported: dateReported ?? this.dateReported,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      verificationQuestion: verificationQuestion ?? this.verificationQuestion,
      secretAnswerHash: secretAnswerHash ?? this.secretAnswerHash,
      acceptedClaimId: acceptedClaimId ?? this.acceptedClaimId,
      handoverCodeHash: handoverCodeHash ?? this.handoverCodeHash,
      handoverCompletedAt: handoverCompletedAt ?? this.handoverCompletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      syncError: syncError ?? this.syncError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
