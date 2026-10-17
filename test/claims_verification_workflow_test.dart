import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/core/models/item_model.dart';
import 'package:finders_keepers/core/models/claim_model.dart';
import 'package:finders_keepers/core/models/user_model.dart';
import 'package:finders_keepers/core/services/local_storage_service.dart';
import 'package:finders_keepers/core/services/item_service.dart';
import 'package:finders_keepers/core/services/claim_service.dart';

void main() {
  late LocalStorageService storage;
  late ItemService itemService;
  late ClaimService claimService;

  final finder = const AppUser(
    id: 'usr_finder_1',
    email: 'finder@vitstudent.ac.in',
    displayName: 'Finder Diya',
    studentId: '23BCE1001',
    role: 'student',
  );

  final claimantA = const AppUser(
    id: 'usr_claimant_a',
    email: 'claimant_a@vitstudent.ac.in',
    displayName: 'Claimant Aarav',
    studentId: '23BCE1002',
    role: 'student',
  );

  final claimantB = const AppUser(
    id: 'usr_claimant_b',
    email: 'claimant_b@vitstudent.ac.in',
    displayName: 'Claimant Rohan',
    studentId: '23BCE1003',
    role: 'student',
  );

  final unauthorizedUser = const AppUser(
    id: 'usr_intruder',
    email: 'intruder@vitstudent.ac.in',
    displayName: 'Intruder',
    studentId: '23BCE9999',
    role: 'student',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);
    itemService = ItemService(storage);
    claimService = ClaimService(storage, itemService);
  });

  group('Item Reporting & Offline Queueing Workflow', () {
    test('Reporting an item online saves as synced', () async {
      await storage.setSimulatedOffline(false);

      final item = await itemService.reportItem(
        title: 'Casio Calculator',
        description: 'Scientific calculator left in library',
        category: 'books_notes',
        type: ItemType.found,
        campusLocationId: 'lib',
        campusLocationName: 'Central Library',
        latitude: 12.9692,
        longitude: 79.1565,
        reporterId: finder.id,
        reporterName: finder.displayName,
        verificationQuestion: 'What name is etched inside the slide cover?',
      );

      expect(item.syncStatus, SyncStatus.synced);
      expect(storage.getOutboxTasks().isEmpty, isTrue);
    });

    test('Reporting an item offline queues in local outbox with queuedLocally status', () async {
      await storage.setSimulatedOffline(true);

      final item = await itemService.reportItem(
        title: 'Offline Hostel Keys',
        description: 'Found outside Q block',
        category: 'keys',
        type: ItemType.found,
        campusLocationId: 'mens_hostel',
        campusLocationName: "Men's Hostel",
        latitude: 12.9725,
        longitude: 79.1620,
        reporterId: finder.id,
        reporterName: finder.displayName,
      );

      expect(item.syncStatus, SyncStatus.queuedLocally);
      final outbox = storage.getOutboxTasks();
      expect(outbox.length, 1);
      expect(outbox.first.type, 'create_item');

      // Now sync outbox
      await storage.setSimulatedOffline(false);
      final syncedCount = await itemService.syncOfflineTasks();
      expect(syncedCount, 1);

      final updated = itemService.getItemById(item.id);
      expect(updated?.syncStatus, SyncStatus.synced);
    });
  });

  group('Claim Submission & Authorization Workflow', () {
    late ItemModel foundEarphones;

    setUp(() async {
      foundEarphones = await itemService.reportItem(
        title: 'Sony WF-1000XM4 Earbuds',
        description: 'Found black charging case in TT ground floor lobby',
        category: 'audio',
        type: ItemType.found,
        campusLocationId: 'tt',
        campusLocationName: 'Technology Tower',
        latitude: 12.9701,
        longitude: 79.1578,
        reporterId: finder.id,
        reporterName: finder.displayName,
        verificationQuestion: 'Describe the scratches or inner lid markings.',
      );
    });

    test(
      'Finder cannot submit an ownership claim on their own reported item',
      () async {
        expect(
          () => claimService.submitClaim(
            itemId: foundEarphones.id,
            claimant: finder,
            proofDescription: 'Actually this was mine all along',
            answerToQuestion: 'I am the finder',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Claimant can submit ownership claim with non-public verification answer',
      () async {
        final claim = await claimService.submitClaim(
          itemId: foundEarphones.id,
          claimant: claimantA,
          proofDescription:
              'Dropped out of my backpack during morning lecture at 10 AM',
          answerToQuestion:
              'Right earbud has a small dent near the microphone mesh',
        );

        expect(claim.status, ClaimStatus.pending);
        expect(claim.claimantId, claimantA.id);
        expect(claim.answerToQuestion, contains('dent near the microphone'));
      },
    );

    test(
      'Prevent duplicate pending claims by the same claimant on the same item',
      () async {
        await claimService.submitClaim(
          itemId: foundEarphones.id,
          claimant: claimantA,
          proofDescription: 'First claim attempt',
          answerToQuestion: 'Answer 1',
        );

        expect(
          () => claimService.submitClaim(
            itemId: foundEarphones.id,
            claimant: claimantA,
            proofDescription: 'Duplicate attempt',
            answerToQuestion: 'Answer 1 duplicate',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'Privacy Isolation: Regular students can only view their own claims',
      () async {
        await claimService.submitClaim(
          itemId: foundEarphones.id,
          claimant: claimantA,
          proofDescription: 'Claimant A proof',
          answerToQuestion: 'Secret answer from A',
        );

        await claimService.submitClaim(
          itemId: foundEarphones.id,
          claimant: claimantB,
          proofDescription: 'Claimant B proof',
          answerToQuestion: 'Secret answer from B',
        );

        // Finder sees all claims for the item
        final finderClaims = claimService.getClaimsForItem(
          itemId: foundEarphones.id,
          user: finder,
        );
        expect(finderClaims.length, 2);

        // Claimant A only sees their own claim, NOT Claimant B's
        final claimantAClaims = claimService.getClaimsForItem(
          itemId: foundEarphones.id,
          user: claimantA,
        );
        expect(claimantAClaims.length, 1);
        expect(claimantAClaims.first.claimantId, claimantA.id);

        // Unauthorized third party sees 0 claims
        final intruderClaims = claimService.getClaimsForItem(
          itemId: foundEarphones.id,
          user: unauthorizedUser,
        );
        expect(intruderClaims.isEmpty, isTrue);
      },
    );

    test('Claim Approval: Only finder can approve; generates 6-digit OTP and marks item claimed', () async {
      final claimA = await claimService.submitClaim(
        itemId: foundEarphones.id,
        claimant: claimantA,
        proofDescription: 'Claimant A proof',
        answerToQuestion: 'Exact correct description of dent',
      );

      await claimService.submitClaim(
        itemId: foundEarphones.id,
        claimant: claimantB,
        proofDescription: 'Claimant B proof',
        answerToQuestion: 'Vague description',
      );

      // Intruder attempting to approve throws Unauthorized Exception
      expect(
        () => claimService.approveClaim(
          claimId: claimA.id,
          reviewer: unauthorizedUser,
        ),
        throwsA(isA<Exception>()),
      );

      // Finder approves Claim A
      await claimService.approveClaim(claimId: claimA.id, reviewer: finder);

      // Item transitions to 'claimed' and has salted hash
      final updatedItem = itemService.getItemById(foundEarphones.id)!;
      expect(updatedItem.status, ItemStatus.claimed);
      expect(updatedItem.acceptedClaimId, claimA.id);
      expect(updatedItem.handoverCodeHash, isNotNull);

      // Claim A receives 6-digit handover OTP
      final updatedClaims = claimService.getMySubmittedClaims(claimantA.id);
      final approvedClaimA = updatedClaims.first;
      expect(approvedClaimA.status, ClaimStatus.approved);
      expect(approvedClaimA.handoverCode, isNotNull);
      expect(approvedClaimA.handoverCode!.length, 6);

      // Competing claim B is rejected
      final claimsForB = claimService.getMySubmittedClaims(claimantB.id);
      expect(claimsForB.first.status, ClaimStatus.rejected);
    });

    test('In-Person Handover Verification: Validating OTP transitions item to returned', () async {
      final claimA = await claimService.submitClaim(
        itemId: foundEarphones.id,
        claimant: claimantA,
        proofDescription: 'Proof',
        answerToQuestion: 'Answer',
      );

      await claimService.approveClaim(claimId: claimA.id, reviewer: finder);

      final approvedClaim = claimService
          .getMySubmittedClaims(claimantA.id)
          .first;
      final handoverOtp = approvedClaim.handoverCode!;

      // Finder enters wrong OTP -> Fails
      expect(
        () => claimService.verifyAndCompleteHandover(
          itemId: foundEarphones.id,
          enteredOtp: '000000',
          reviewer: finder,
        ),
        throwsA(isA<Exception>()),
      );

      // Finder enters matching OTP -> Succeeds
      final success = await claimService.verifyAndCompleteHandover(
        itemId: foundEarphones.id,
        enteredOtp: handoverOtp,
        reviewer: finder,
      );

      expect(success, isTrue);

      final returnedItem = itemService.getItemById(foundEarphones.id)!;
      expect(returnedItem.status, ItemStatus.returned);
      expect(returnedItem.handoverCompletedAt, isNotNull);

      final completedClaim = claimService
          .getMySubmittedClaims(claimantA.id)
          .first;
      expect(completedClaim.status, ClaimStatus.handedOver);
    });
  });
}
