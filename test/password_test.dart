import 'package:flutter_test/flutter_test.dart';

import 'package:lms_app/models/user.dart';
import 'package:lms_app/utils/password.dart';

void main() {
  group('Password hashing', () {
    test('verifies a correct password and rejects a wrong one', () {
      final salt = generateSalt();
      final hash = hashPassword('s3cret!', salt);
      expect(verifyPassword('s3cret!', salt, hash), isTrue);
      expect(verifyPassword('wrong', salt, hash), isFalse);
    });

    test('same password with different salts yields different hashes', () {
      final hashA = hashPassword('pw', generateSalt());
      final hashB = hashPassword('pw', generateSalt());
      expect(hashA, isNot(equals(hashB)));
    });

    test('hashing is deterministic for a fixed salt', () {
      const salt = 'fixed-salt';
      expect(hashPassword('pw', salt), hashPassword('pw', salt));
    });
  });

  group('AppUser credentials', () {
    test('round-trips password salt and hash through a map', () {
      final salt = generateSalt();
      final user = AppUser(
        id: 'u1',
        name: 'Test User',
        email: 'test@lms.dev',
        role: UserRole.student,
        passwordSalt: salt,
        passwordHash: hashPassword('pw123456', salt),
      );
      expect(user.hasPassword, isTrue);
      final restored = AppUser.fromMap(user.toMap());
      expect(restored.passwordSalt, user.passwordSalt);
      expect(restored.passwordHash, user.passwordHash);
      expect(
        verifyPassword('pw123456', restored.passwordSalt!, restored.passwordHash!),
        isTrue,
      );
    });

    test('legacy user without a password reports hasPassword false', () {
      const user = AppUser(
        id: 'u2',
        name: 'Legacy',
        email: 'legacy@lms.dev',
        role: UserRole.instructor,
      );
      expect(user.hasPassword, isFalse);
      final restored = AppUser.fromMap(user.toMap());
      expect(restored.hasPassword, isFalse);
    });
  });
}
