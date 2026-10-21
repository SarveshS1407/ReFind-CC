enum ClaimStatus {
  pending,
  underReview,
  moreInfoNeeded,
  approved,
  rejected,
  handedOver,
  withdrawn,
}

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
  final String? moreInfoRequest;
  final String? moreInfoResponse;

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
    this.moreInfoRequest,
    this.moreInfoResponse,
    this.handoverCode,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == ClaimStatus.pending;
  bool get isUnderReview => status == ClaimStatus.underReview;
  bool get isMoreInfoNeeded => status == ClaimStatus.moreInfoNeeded;
  bool get isApproved => status == ClaimStatus.approved;
  bool get isRejected => status == ClaimStatus.rejected;
  bool get isHandedOver => status == ClaimStatus.handedOver;
  bool get isWithdrawn => status == ClaimStatus.withdrawn;
  bool get isTerminal => isRejected || isHandedOver || isWithdrawn;

  String get displayStatus {
    switch (status) {
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.moreInfoNeeded:
        return 'More Info Required';
      case ClaimStatus.approved:
        return 'Approved — OTP Ready';
      case ClaimStatus.rejected:
        return 'Claim Rejected';
      case ClaimStatus.handedOver:
        return 'Item Returned';
      case ClaimStatus.withdrawn:
        return 'Claim Withdrawn';
    }
  }

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
      'moreInfoRequest': moreInfoRequest,
      'moreInfoResponse': moreInfoResponse,
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
      moreInfoRequest: map['moreInfoRequest'],
      moreInfoResponse: map['moreInfoResponse'],
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
    String? moreInfoRequest,
    String? moreInfoResponse,
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
      moreInfoRequest: moreInfoRequest ?? this.moreInfoRequest,
      moreInfoResponse: moreInfoResponse ?? this.moreInfoResponse,
      handoverCode: handoverCode ?? this.handoverCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
