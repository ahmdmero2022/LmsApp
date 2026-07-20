import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a random, URL-safe salt for password hashing.
String generateSalt([int length = 16]) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

/// Hashes [password] with [salt] using SHA-256.
String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}

/// Returns true when [password] matches the stored [salt]/[hash] pair.
bool verifyPassword(String password, String salt, String hash) {
  return hashPassword(password, salt) == hash;
}
