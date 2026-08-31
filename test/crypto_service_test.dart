import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/services/crypto_service.dart';
import 'package:notey/core/services/note_lock_service.dart';
import 'package:notey/features/notes/model/note.dart';

void main() {
  setUp(() {
    // Keep PBKDF2 fast in tests; production values are covered by the
    // format tests below.
    CryptoService.pbkdf2Iterations = 1000;
    PinHasher.pbkdf2Iterations = 1000;
    // Disable the production floor so tests can assert exact iteration counts.
    CryptoService.minIterations = 0;
  });

  group('CryptoService.encryptField / decryptField', () {
    test('round-trips arabic text', () async {
      final salt = CryptoService.newSalt();
      final cipher = await CryptoService.encryptField(
        plain: 'نصّ سري 🔐 123',
        password: 'كلمة السر',
        salt: salt,
      );

      expect(cipher, isNot(contains('سري')));
      final plain = await CryptoService.decryptField(
        stored: cipher,
        password: 'كلمة السر',
        salt: salt,
      );
      expect(plain, 'نصّ سري 🔐 123');
    });

    test('v2 format embeds the iteration count', () async {
      CryptoService.pbkdf2Iterations = 1234;
      final cipher = await CryptoService.encryptField(
        plain: 'x', password: 'p', salt: CryptoService.newSalt(),
      );
      expect(cipher.startsWith('v2.1234.'), isTrue);
    });

    test('wrong password throws SecretBoxAuthenticationError', () async {
      final salt = CryptoService.newSalt();
      final cipher = await CryptoService.encryptField(
        plain: 'secret', password: 'right', salt: salt,
      );
      expect(
        () => CryptoService.decryptField(stored: cipher, password: 'wrong', salt: salt),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('malformed payloads throw FormatException', () async {
      expect(
        () => CryptoService.decryptField(
          stored: 'not-a-cipher', password: 'p', salt: CryptoService.newSalt(),
        ),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => CryptoService.decryptField(
          stored: 'v2.bad.format.here', password: 'p', salt: CryptoService.newSalt(),
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('legacy v1 payload (60k iterations) stays decryptable', () async {
      // Reproduce the pre-v2 format exactly as the old app version wrote it.
      const iterations = 60000;
      final salt = CryptoService.newSalt();
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: 'old-pin', nonce: base64Decode(salt));
      final box = await AesGcm.with256bits().encrypt(
        utf8.encode('بيانات قديمة'),
        secretKey: key,
        nonce: List<int>.generate(12, (i) => i),
      );
      final legacy =
          '${base64Encode(box.nonce)}.${base64Encode(box.cipherText)}.${base64Encode(box.mac.bytes)}';

      final plain = await CryptoService.decryptField(
        stored: legacy,
        password: 'old-pin',
        salt: salt,
      );
      expect(plain, 'بيانات قديمة');
    });
  });

  group('PinHasher', () {
    test('create/verify round-trip', () async {
      final stored = await PinHasher.create('4821');
      expect(stored.startsWith('v2:'), isTrue);
      expect(await PinHasher.verify('4821', stored), isTrue);
      expect(await PinHasher.verify('0000', stored), isFalse);
    });

    test('verify accepts the legacy sha256 format', () async {
      final salt = CryptoService.newSalt();
      final digest = await Sha256().hash(utf8.encode('$salt:1357'));
      final legacy = '$salt:${base64Encode(digest.bytes)}';

      expect(await PinHasher.verify('1357', legacy), isTrue);
      expect(await PinHasher.verify('9753', legacy), isFalse);
    });

    test('garbage input never verifies', () async {
      expect(await PinHasher.verify('1234', ''), isFalse);
      expect(await PinHasher.verify('1234', 'v2:nope'), isFalse);
      expect(await PinHasher.verify('1234', 'a:b:c'), isFalse);
    });
  });

  group('NoteLockService', () {
    test('lock hides title/content and unlock restores them', () async {
      final note = Note.create(title: 'عنوان سري', content: 'محتوى سري');
      const password = 'pass-1234';

      final locked = await NoteLockService.lock(note, password);
      expect(locked.isLocked, isTrue);
      expect(locked.lockSalt, isNotNull);
      expect(locked.title, isNot('عنوان سري'));
      expect(locked.content, isNot('محتوى سري'));

      // The locked copy must persist as-is and come back encrypted.
      final map = Map<String, Object?>.from(locked.toMap());
      final reloaded = Note.fromMap(map);
      expect(reloaded.isLocked, isTrue);

      final unlocked = await NoteLockService.unlock(reloaded, password);
      expect(unlocked.title, 'عنوان سري');
      expect(unlocked.content, 'محتوى سري');

      expect(
        () => NoteLockService.unlock(reloaded, 'bad'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('derived-key cache serves repeated unlocks but stays correct', () async {
      final note = Note.create(title: 'عنوان سري', content: 'محتوى سري');
      const password = 'pass-1234';

      final locked = await NoteLockService.lock(note, password);
      final map = Map<String, Object?>.from(locked.toMap());
      final reloaded = Note.fromMap(map);

      // First unlock populates the cache; a second unlock for the same note
      // with the same password hits the cache and still decrypts correctly.
      final first = await NoteLockService.unlock(reloaded, password);
      final second = await NoteLockService.unlock(reloaded, password);
      expect(first.title, 'عنوان سري');
      expect(second.title, 'عنوان سري');

      // A wrong password on the same salt must NOT be served from the cache
      // (it would collide only if the cache key ignored the password).
      expect(
        () => NoteLockService.unlock(reloaded, 'wrong'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );

      // Clearing the cache keeps everything working.
      CryptoService.clearKeyCache();
      final afterClear = await NoteLockService.unlock(reloaded, password);
      expect(afterClear.title, 'عنوان سري');
    });

    test('removeLock clears protection flags', () async {
      final note = Note.create(title: 't', content: 'c');
      final locked = await NoteLockService.lock(note, 'pw');
      final unlocked = await NoteLockService.removeLock(locked);
      expect(unlocked.isLocked, isFalse);
      expect(unlocked.lockSalt, isNull);
    });
  });
}
