enum ClaimStatus { pending, approved, rejected, handedOver }

class ClaimModel {
  final String id;
  final String itemId;
  final String claimantId;
  final String claimantName;
  final String claimantContact;
  final String proofDescription;

  // Non-public answer to the finder's verification challenge
  // PRIVACY: Only readable by the Item Reporter and the Claimant!
  final String answerToQuestion;
  final String? proofImageUrl;

  final ClaimStatus status;
  final String? rejectionReason;

  // 6-digit plain OTP generated upon approval, visible only to claimant.
  // The finder validates this token before physically handing over the item.
  final String? handoverCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.claimantName,
    required this.claimantContact,
    required this.proofDescription,
    required this.answerToQuestion,
    this.proofImageUrl,
    this.status = ClaimStatus.pending,
    this.rejectionReason,
    this.handoverCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == ClaimStatus.pending;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;
  bool get isHandedOver => status == ClaimStatus.handedOver;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'claimantId': claimantId,
      'claimantName': claimantName,
      'claimantContact': claimantContact,
      'proofDescription': proofDescription,
      'answerToQuestion': answerToQuestion,
      'proofImageUrl': proofImageUrl,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'handoverCode': handoverCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ClaimModel.fromMap(Map<String, dynamic> map) {
    return ClaimModel(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      claimantId: map['claimantId'] ?? '',
      claimantName: map['claimantName'] ?? 'Student',
      claimantContact: map['claimantContact'] ?? '',
      proofDescription: map['proofDescription'] ?? '',
      answerToQuestion: map['answerToQuestion'] ?? '',
      proofImageUrl: map['proofImageUrl'],
      status: ClaimStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ClaimStatus.pending,
      ),
      rejectionReason: map['rejectionReason'],
      handoverCode: map['handoverCode'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
    );
  }

  ClaimModel copyWith({
    String? id,
    String? itemId,
    String? claimantId,
    String? claimantName,
    String? claimantContact,
    String? proofDescription,
    String? answerToQuestion,
    String? proofImageUrl,
    ClaimStatus? status,
    String? rejectionReason,
    String? handoverCode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClaimModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      claimantId: claimantId ?? this.claimantId,
      claimantName: claimantName ?? this.claimantName,
      claimantContact: claimantContact ?? this.claimantContact,
      proofDescription: proofDescription ?? this.proofDescription,
      answerToQuestion: answerToQuestion ?? this.answerToQuestion,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      handoverCode: handoverCode ?? this.handoverCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
