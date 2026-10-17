import 'package:uuid/uuid.dart';

import '../models/claim_model.dart';
import '../models/item_model.dart';
import '../models/user_model.dart';
import '../utils/crypto_utils.dart';
import 'local_storage_service.dart';
import 'item_service.dart';

class ClaimService {
  final LocalStorageService _storage;
  final ItemService _itemService;
  List<ClaimModel> _claims = [];

  ClaimService(this._storage, this._itemService) {
    _loadInitialClaims();
  }

  void _loadInitialClaims() {
    _claims = _storage.getClaims();
  }

  List<ClaimModel> get allClaims => List.unmodifiable(_claims);

  /// Submits an ownership claim on a reported item
  Future<ClaimModel> submitClaim({
    required String itemId,
    required AppUser claimant,
    required String proofDescription,
    required String answerToQuestion,
    String? proofImageUrl,
  }) async {
    final item = _itemService.getItemById(itemId);
    if (item == null) {
      throw Exception('Target item not found.');
    }

    if (item.reporterId == claimant.id) {
      throw Exception(
        'You cannot submit an ownership claim on your own reported item.',
      );
    }

    // Check if claimant already has a pending claim on this item
    final existing = _claims.where(
      (c) => c.itemId == itemId && c.claimantId == claimant.id && c.isPending,
    );
    if (existing.isNotEmpty) {
      throw Exception(
        'You already have a pending verification claim on this item.',
      );
    }

    final now = DateTime.now();
    final newClaim = ClaimModel(
      id: 'clm_${const Uuid().v4().substring(0, 8)}',
      itemId: itemId,
      claimantId: claimant.id,
      claimantName: claimant.displayName,
      claimantContact: claimant.email,
      proofDescription: proofDescription.trim(),
      answerToQuestion: answerToQuestion.trim(),
      proofImageUrl: proofImageUrl,
      status: ClaimStatus.pending,
      createdAt: now,
      updatedAt: now,
    );

    _claims.insert(0, newClaim);
    await _storage.saveClaims(_claims);
    return newClaim;
  }

  /// Retrieves claims for a specific item with strict authorization checks
  List<ClaimModel> getClaimsForItem({
    required String itemId,
    required AppUser user,
  }) {
    final item = _itemService.getItemById(itemId);
    if (item == null) return [];

    // Authorization: Item reporter or moderator can see all claims for this item
    if (item.reporterId == user.id || user.isModerator) {
      return _claims.where((c) => c.itemId == itemId).toList();
    }

    // Otherwise, normal student can ONLY view their own claim
    return _claims
        .where((c) => c.itemId == itemId && c.claimantId == user.id)
        .toList();
  }

  /// Retrieves all claims submitted by the given user
  List<ClaimModel> getMySubmittedClaims(String claimantId) {
    return _claims.where((c) => c.claimantId == claimantId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Retrieves all claims on items reported by this finder
  List<ClaimModel> getClaimsForMyReportedItems(String finderId) {
    final myItemIds = _itemService.allItems
        .where((i) => i.reporterId == finderId)
        .map((i) => i.id)
        .toSet();
    return _claims.where((c) => myItemIds.contains(c.itemId)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Finder reviews and accepts a claim, generating a secure 6-digit Handover Token
  Future<void> approveClaim({
    required String claimId,
    required AppUser reviewer,
  }) async {
    final claimIndex = _claims.indexWhere((c) => c.id == claimId);
    if (claimIndex == -1) throw Exception('Claim not found.');

    final claim = _claims[claimIndex];
    final item = _itemService.getItemById(claim.itemId);
    if (item == null) throw Exception('Associated item not found.');

    // Enforce authorization
    if (item.reporterId != reviewer.id && !reviewer.isModerator) {
      throw Exception(
        'Unauthorized: Only the item finder or a moderator can approve this claim.',
      );
    }

    final now = DateTime.now();
    // 1. Generate 6-digit handover code
    final plainCode = CryptoUtils.generateHandoverCode();
    // 2. Hash code with item ID as salt
    final saltedHash = CryptoUtils.hashHandoverCode(plainCode, item.id);

    // 3. Update the claim with the plaintext code (visible only to the claimant)
    final updatedClaim = claim.copyWith(
      status: ClaimStatus.approved,
      handoverCode: plainCode,
      updatedAt: now,
    );
    _claims[claimIndex] = updatedClaim;

    // 4. Update the item state to 'claimed' with the hashed token
    final updatedItem = item.copyWith(
      status: ItemStatus.claimed,
      acceptedClaimId: claim.id,
      handoverCodeHash: saltedHash,
      updatedAt: now,
    );
    await _itemService.updateItem(updatedItem);

    // 5. Reject other pending claims for this item
    for (int i = 0; i < _claims.length; i++) {
      if (_claims[i].itemId == item.id &&
          _claims[i].id != claim.id &&
          _claims[i].isPending) {
        _claims[i] = _claims[i].copyWith(
          status: ClaimStatus.rejected,
          rejectionReason:
              'Another student submitted a verified ownership match.',
          updatedAt: now,
        );
      }
    }

    await _storage.saveClaims(_claims);
  }

  /// Finder rejects an invalid or fraudulent claim
  Future<void> rejectClaim({
    required String claimId,
    required AppUser reviewer,
    required String reason,
  }) async {
    final claimIndex = _claims.indexWhere((c) => c.id == claimId);
    if (claimIndex == -1) throw Exception('Claim not found.');

    final claim = _claims[claimIndex];
    final item = _itemService.getItemById(claim.itemId);
    if (item == null) throw Exception('Associated item not found.');

    if (item.reporterId != reviewer.id && !reviewer.isModerator) {
      throw Exception(
        'Unauthorized: Only the item reporter or a moderator can reject claims.',
      );
    }

    final now = DateTime.now();
    _claims[claimIndex] = claim.copyWith(
      status: ClaimStatus.rejected,
      rejectionReason: reason.trim().isNotEmpty
          ? reason.trim()
          : 'Verification details did not match finder specifications.',
      updatedAt: now,
    );

    await _storage.saveClaims(_claims);
  }

  /// Verifies physical handover using the 6-digit OTP presented in-person
  Future<bool> verifyAndCompleteHandover({
    required String itemId,
    required String enteredOtp,
    required AppUser reviewer,
  }) async {
    final item = _itemService.getItemById(itemId);
    if (item == null) throw Exception('Item not found.');

    if (item.reporterId != reviewer.id && !reviewer.isModerator) {
      throw Exception(
        'Unauthorized: Only the item finder or a moderator can verify handover.',
      );
    }

    if (item.status != ItemStatus.claimed || item.handoverCodeHash == null) {
      throw Exception(
        'Item is not in a claimed state awaiting handover verification.',
      );
    }

    // Verify OTP against salted hash
    final isValid = CryptoUtils.verifyHandoverCode(
      enteredCode: enteredOtp,
      salt: item.id,
      storedHash: item.handoverCodeHash!,
    );

    if (!isValid) {
      throw Exception('Incorrect handover code. Verification failed.');
    }

    final now = DateTime.now();
    // 1. Transition item to 'returned'
    final updatedItem = item.copyWith(
      status: ItemStatus.returned,
      handoverCompletedAt: now,
      updatedAt: now,
    );
    await _itemService.updateItem(updatedItem);

    // 2. Transition accepted claim to 'handedOver'
    final claimIndex = _claims.indexWhere((c) => c.id == item.acceptedClaimId);
    if (claimIndex != -1) {
      _claims[claimIndex] = _claims[claimIndex].copyWith(
        status: ClaimStatus.handedOver,
        updatedAt: now,
      );
      await _storage.saveClaims(_claims);
    }

    return true;
  }
}
