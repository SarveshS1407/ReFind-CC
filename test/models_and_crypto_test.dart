import 'package:flutter_test/flutter_test.dart';
import 'package:finders_keepers/core/utils/crypto_utils.dart';
import 'package:finders_keepers/core/utils/formatters.dart';
import 'package:finders_keepers/core/models/item_model.dart';
import 'package:finders_keepers/core/models/claim_model.dart';

void main() {
  group('CryptoUtils Tests', () {
    test('generateHandoverCode generates a 6-digit numeric string', () {
      for (int i = 0; i < 20; i++) {
        final code = CryptoUtils.generateHandoverCode();
        expect(code.length, 6);
        expect(int.tryParse(code), isNotNull);
        expect(int.parse(code) >= 100000, isTrue);
        expect(int.parse(code) <= 999999, isTrue);
      }
    });

    test('hashHandoverCode and verifyHandoverCode validate matching codes', () {
      const code = '582194';
      const salt = 'itm_test_item_99';
      final storedHash = CryptoUtils.hashHandoverCode(code, salt);

      expect(storedHash, isNotEmpty);
      expect(
        CryptoUtils.verifyHandoverCode(
          enteredCode: '582194',
          salt: salt,
          storedHash: storedHash,
        ),
        isTrue,
      );

      // Whitespace tolerance
      expect(
        CryptoUtils.verifyHandoverCode(
          enteredCode: ' 582194 ',
          salt: salt,
          storedHash: storedHash,
        ),
        isTrue,
      );
    });

    test('verifyHandoverCode rejects mismatched or invalid codes', () {
      const code = '582194';
      const salt = 'itm_test_item_99';
      final storedHash = CryptoUtils.hashHandoverCode(code, salt);

      expect(
        CryptoUtils.verifyHandoverCode(
          enteredCode: '123456',
          salt: salt,
          storedHash: storedHash,
        ),
        isFalse,
      );

      // Wrong salt rejects
      expect(
        CryptoUtils.verifyHandoverCode(
          enteredCode: '582194',
          salt: 'different_item_id',
          storedHash: storedHash,
        ),
        isFalse,
      );
    });
  });

  group('ItemModel Serialization & Lifecycle Tests', () {
    test('ItemModel correctly round-trips toMap and fromMap', () {
      final now = DateTime.now();
      final item = ItemModel(
        id: 'itm_test_1',
        title: 'Blue Water Bottle',
        description: 'Milton 1L flask forgotten in SJT 401',
        category: 'bottles',
        type: ItemType.found,
        status: ItemStatus.found,
        campusLocationId: 'sjt',
        campusLocationName: 'Silver Jubilee Tower (SJT)',
        latitude: 12.9712,
        longitude: 79.1593,
        reporterId: 'usr_1',
        reporterName: 'Diya Patel',
        reporterContact: 'diya@vitstudent.ac.in',
        dateReported: now,
        verificationQuestion: 'What stickers are on the cap?',
        createdAt: now,
        updatedAt: now,
      );

      final map = item.toMap();
      final restored = ItemModel.fromMap(map);

      expect(restored.id, item.id);
      expect(restored.title, item.title);
      expect(restored.type, ItemType.found);
      expect(restored.status, ItemStatus.found);
      expect(restored.isApproximateLocation, isTrue);
      expect(restored.verificationQuestion, 'What stickers are on the cap?');
    });

    test('ItemModel state getters reflect correct lifecycle', () {
      final now = DateTime.now();
      final base = ItemModel(
        id: 'itm_test_2',
        title: 'Laptop Charger',
        description: 'Dell 65W USB-C',
        category: 'electronics',
        type: ItemType.lost,
        status: ItemStatus.lost,
        campusLocationId: 'tt',
        campusLocationName: 'Technology Tower',
        latitude: 12.9701,
        longitude: 79.1578,
        reporterId: 'usr_2',
        reporterName: 'Aarav Sharma',
        dateReported: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(base.isLost, isTrue);
      expect(base.isFound, isFalse);
      expect(base.isClaimed, isFalse);
      expect(base.isReturned, isFalse);

      final claimed = base.copyWith(status: ItemStatus.claimed);
      expect(claimed.isClaimed, isTrue);

      final returned = claimed.copyWith(status: ItemStatus.returned);
      expect(returned.isReturned, isTrue);
    });
  });

  group('ClaimModel Tests', () {
    test('ClaimModel stores private verification details and round-trips', () {
      final now = DateTime.now();
      final claim = ClaimModel(
        id: 'clm_1',
        itemId: 'itm_test_1',
        claimantId: 'usr_claimant_1',
        claimantName: 'Rohan Gupta',
        claimantContact: 'rohan@vitstudent.ac.in',
        proofDescription: 'I left it after CAT 1 exams on row 4 desk 2',
        answerToQuestion: 'Has a Pikachu sticker on the bottom',
        status: ClaimStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final map = claim.toMap();
      final restored = ClaimModel.fromMap(map);

      expect(restored.id, claim.id);
      expect(restored.answerToQuestion, 'Has a Pikachu sticker on the bottom');
      expect(restored.isPending, isTrue);
      expect(restored.isApproved, isFalse);
    });
  });

  group('Formatters & Distance Calculation Tests', () {
    test('calculateDistanceMeters computes reasonable campus distances', () {
      // Distance between SJT and Technology Tower
      final dist = Formatters.calculateDistanceMeters(
        12.9712,
        79.1593, // SJT
        12.9701,
        79.1578, // TT
      );

      // Distance between SJT and TT is approximately 200m
      expect(dist > 100, isTrue);
      expect(dist < 400, isTrue);
    });

    test('computeTextSimilarity detects word overlap', () {
      final sim1 = Formatters.computeTextSimilarity(
        'Apple AirPods Pro white case',
        'AirPods Pro case in white',
      );
      expect(sim1 > 0.4, isTrue);

      final sim2 = Formatters.computeTextSimilarity(
        'Hostel room keys with Spider-Man keychain',
        'Casio scientific calculator fx-991CW',
      );
      expect(sim2, 0.0);
    });
  });
}
