import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Hashes a string using standard SHA-256
  static String hashString(String input) {
    final bytes = utf8.encode(input.trim().toLowerCase());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generates a cryptographically secure 6-digit numerical OTP code
  static String generateHandoverCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  /// Returns a salted SHA-256 hash of the 6-digit handover token
  static String hashHandoverCode(String code, String salt) {
    final combined = '$salt:$code';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies if an entered handover code matches the stored salted hash
  static bool verifyHandoverCode({
    required String enteredCode,
    required String salt,
    required String storedHash,
  }) {
    final computed = hashHandoverCode(enteredCode.trim(), salt);
    return computed == storedHash.trim();
  }
}
