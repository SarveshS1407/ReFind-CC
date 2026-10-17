enum SyncTaskStatus { pending, syncing, failed, completed }

class OfflineSyncTask {
  final String id;
  final String
  type; // 'create_item' | 'submit_claim' | 'approve_claim' | 'verify_handover'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final SyncTaskStatus status;
  final String? lastError;

  const OfflineSyncTask({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncTaskStatus.pending,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'status': status.name,
      'lastError': lastError,
    };
  }

  factory OfflineSyncTask.fromMap(Map<String, dynamic> map) {
    return OfflineSyncTask(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      retryCount: map['retryCount'] ?? 0,
      status: SyncTaskStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SyncTaskStatus.pending,
      ),
      lastError: map['lastError'],
    );
  }

  OfflineSyncTask copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    SyncTaskStatus? status,
    String? lastError,
  }) {
    return OfflineSyncTask(
      id: id ?? this.id,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }
}
