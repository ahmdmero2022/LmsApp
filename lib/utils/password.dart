import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// PBKDF2 work factor. High enough to slow brute-force attacks, low enough to
/// stay responsive for a single interactive login on the web.
const int _iterations = 100000;

/// Derived key length in bytes.
const int _keyLength = 32;

/// Generates a random, URL-safe salt for password hashing.
String generateSalt([int length = 16]) {
  final random = Random.secure();
  final bytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

/// Hashes [password] with [salt] using PBKDF2-HMAC-SHA256, returning a
/// base64-encoded derived key.
String hashPassword(String password, String salt) {
  final derived = _pbkdf2(
    utf8.encode(password),
    utf8.encode(salt),
    _iterations,
    _keyLength,
  );
  return base64.encode(derived);
}

/// Returns true when [password] matches the stored [salt]/[hash] pair, using a
/// constant-time comparison to avoid leaking timing information.
bool verifyPassword(String password, String salt, String hash) {
  return _constantTimeEquals(hashPassword(password, salt), hash);
}

List<int> _pbkdf2(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  const hashLength = 32;
  final blockCount = (keyLength + hashLength - 1) ~/ hashLength;
  final result = <int>[];
  for (var block = 1; block <= blockCount; block++) {
    final blockIndex = [
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
    var u = hmac.convert([...salt, ...blockIndex]).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }
    result.addAll(t);
  }
  return result.sublist(0, keyLength);
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
