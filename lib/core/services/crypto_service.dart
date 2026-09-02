import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:cryptography/cryptography.dart';

/// Note-field encryption (AES-GCM) + password hashing for the app PIN.
abstract final class CryptoService {
  /// Bounded LRU-ish in-memory cache of derived keys keyed by a HMAC of
  /// (password, salt, iterations). PBKDF2 is the most expensive step in
  /// encrypt/decrypt (hundreds of thousands of iterations), so caching the
  /// derived key lets repeated unlocks/verifies with the same password skip
  /// the KDF entirely — a big win for rapidly navigating locked notes. Only
  /// already-derived key bytes are held (never the plaintext password), and
  /// AES-GCM still authenticates on every decrypt, so a wrong password on
  /// first try simply misses the cache and re-derives as before.
  ///
  /// The cache is capped so memory stays bounded and test isolation (where
  /// iteration counts are lowered per-test) never sees stale keys.
  static const int _keyCacheCapacity = 16;
  static final Map<String, List<int>> _keyCache = <String, List<int>>{};
  static final List<String> _keyCacheOrder = <String>[];

  /// Current PBKDF2 iteration count for new encryptions. Mutable so tests
  /// can lower it; existing data stays readable because the count is stored.
  /// Minimum 100,000 to prevent accidental weak encryption.
  static int pbkdf2Iterations = 250000;

  /// Floor for pbkdf2Iterations — prevents accidental misconfiguration.
  /// Mutable so tests can lower it.
  static int minIterations = 100000;

  /// Iterations used by the legacy (v1) field format.
  static const int _legacyIterations = 60000;

  static const String _v2Prefix = 'v2';

  /// PBKDF2 iteration count above which the KDF runs on a background isolate
  /// so the UI thread never blocks (fake-async tests stay inline and fast).
  static const int _isolateDeriveThreshold = 20000;

  /// Field encoding:
  /// v1: `nonce.cipherText.mac` (all base64) — legacy, PBKDF2 @ [_legacyIterations].
  /// v2: `v2.<iterations>.nonce.cipherText.mac`.
  static String encode(List<int> nonce, List<int> cipherText, List<int> mac) {
    return '${base64Encode(nonce)}.${base64Encode(cipherText)}.${base64Encode(mac)}';
  }

  static Future<String> encryptField({
    required String plain,
    required String password,
    required String salt,
    SecretKey? preKey,
  }) async {
    final iterations = effectiveIterations;
    final key = preKey ?? await _deriveKey(password, salt, iterations);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(plain),
      secretKey: key,
      nonce: _randomNonce(),
    );
    return '$_v2Prefix.$iterations.${encode(box.nonce, box.cipherText, box.mac.bytes)}';
  }

  /// Throws [SecretBoxAuthenticationError] when the password is wrong.
  /// Throws [FormatException] when the stored value is structurally corrupt.
  static Future<String> decryptField({
    required String stored,
    required String password,
    required String salt,
  }) async {
    final key = await deriveFieldKey(stored: stored, password: password, salt: salt);
    return decryptFieldWithKey(stored: stored, key: key);
  }

  /// Parses the KDF configuration embedded in [stored] and derives the key.
  /// Sharing one derived key across several fields (e.g. a note's title AND
  /// content) halves the PBKDF2 cost of unlocking protected notes.
  static Future<SecretKey> deriveFieldKey({
    required String stored,
    required String password,
    required String salt,
  }) async {
    var iterations = _legacyIterations;
    if (stored.startsWith('$_v2Prefix.')) {
      final parts = stored.split('.');
      if (parts.length != 5) {
        throw const FormatException('Corrupted cipher field');
      }
      iterations = int.tryParse(parts[1]) ?? _legacyIterations;
      if (iterations < 1) {
        throw const FormatException('Invalid iteration count');
      }
    }
    return _deriveKeyCached(password, salt, iterations);
  }

  /// Decrypts a field with an already-derived [key] (see [deriveFieldKey]).
  static Future<String> decryptFieldWithKey({
    required String stored,
    required SecretKey key,
  }) async {
    var payload = stored;
    if (stored.startsWith('$_v2Prefix.')) {
      final parts = stored.split('.');
      if (parts.length != 5) {
        throw const FormatException('Corrupted cipher field');
      }
      payload = parts.sublist(2).join('.');
    }
    final segments = payload.split('.');
    if (segments.length != 3) {
      throw const FormatException('Corrupted cipher field');
    }
    final List<int> nonce;
    final List<int> cipherBytes;
    final List<int> macBytes;
    try {
      nonce = base64Decode(segments[0]);
      cipherBytes = base64Decode(segments[1]);
      macBytes = base64Decode(segments[2]);
    } on FormatException {
      throw const FormatException('Corrupted cipher field');
    }
    final box = SecretBox(
      cipherBytes,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    final decrypted = await AesGcm.with256bits().decrypt(box, secretKey: key);
    return utf8.decode(decrypted);
  }

  static String newSalt() => base64Encode(_randomBytes(16));

  /// Iteration count used for fresh encryptions, floored by [minIterations].
  static int get effectiveIterations =>
      pbkdf2Iterations < minIterations ? minIterations : pbkdf2Iterations;

  /// Derives the key for a fresh encryption with a new salt. PBKDF2 is the
  /// dominant cost of any encrypt/decrypt, so callers (e.g. [NoteLockService])
  /// derive ONCE and pass the key back via [encryptField]'s `preKey` for every
  /// field sharing the same (password, salt) — a lock then runs a single KDF
  /// instead of one per field.
  static Future<SecretKey> deriveKeyForEncryption({
    required String password,
    required String salt,
  }) async {
    return _deriveKeyCached(password, salt, effectiveIterations);
  }

  /// Runs PBKDF2-SHA256 and returns the derived key bytes.
  ///
  /// The KDF is CPU-heavy at production iteration counts, so it is delegated
  /// to a background isolate via [Isolate.run]. Only primitives and plain
  /// byte arrays cross the boundary, so the worker is fully independent.
  /// Low iteration counts (legacy v1 fields, tests) stay inline for speed.
  static Future<List<int>> _pbkdf2Derive(
    String password,
    List<int> nonce,
    int iterations,
  ) {
    if (iterations < _isolateDeriveThreshold) {
      return _pbkdf2Inline(password, nonce, iterations);
    }
    // Offload the CPU-heavy KDF to a background isolate so the UI never
    // blocks. If isolate offloading is unavailable on the current platform
    // (or a sendable-boundary failure occurs), fall back to an inline derive
    // instead of letting a storage/security action crash the whole app.
    try {
      return Isolate.run(
        () async {
          final key = await Pbkdf2(
            macAlgorithm: Hmac.sha256(),
            iterations: iterations,
            bits: 256,
          ).deriveKeyFromPassword(password: password, nonce: nonce);
          return key.extractBytes();
        },
      ).catchError((Object e) {
        debugPrint('CryptoService isolate offload failed — falling back inline: $e');
        return _pbkdf2Inline(password, nonce, iterations);
      });
    } catch (_) {
      return _pbkdf2Inline(password, nonce, iterations);
    }
  }

  static Future<List<int>> _pbkdf2Inline(
    String password,
    List<int> nonce,
    int iterations,
  ) async {
    final key = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKeyFromPassword(password: password, nonce: nonce);
    return key.extractBytes();
  }

  static Future<SecretKey> _deriveKey(
    String password,
    String salt,
    int iterations,
  ) async {
    final bytes = await _pbkdf2Derive(password, base64Decode(salt), iterations);
    return SecretKey(bytes);
  }

  /// Derives a key exactly as [_deriveKey] but memoized across calls so
  /// repeated derives for the same (password, salt, iterations) reuse the
  /// already-computed key. Used by [deriveFieldKey] and by the PIN verifier
  /// — both are hot paths on locked-note navigation.
  static Future<SecretKey> _deriveKeyCached(
    String password,
    String salt,
    int iterations,
  ) async {
    final cacheKey = await _saltKeyCacheKey(password, salt, iterations);
    final hit = _keyCache[cacheKey];
    if (hit != null) return SecretKey(hit);

    final bytes = await _pbkdf2Derive(password, base64Decode(salt), iterations);
    _keyCacheOrder.remove(cacheKey);
    _keyCacheOrder.add(cacheKey);
    if (_keyCacheOrder.length > _keyCacheCapacity) {
      final evicted = _keyCacheOrder.removeAt(0);
      _keyCache.remove(evicted);
    }
    _keyCache[cacheKey] = bytes;
    return SecretKey(bytes);
  }

  /// Builds a stable, non-reversing cache key from the secret + KDF params.
  /// Uses SHA-256 so the key never embeds the plaintext password.
  static Future<String> _saltKeyCacheKey(
    String password,
    String salt,
    int iterations,
  ) async {
    final digest = await Sha256()
        .hash(utf8.encode('$password\u0000$salt\u0000$iterations'));
    return '$iterations:${base64Encode(digest.bytes)}';
  }

  /// Clears the in-memory derived-key cache. Exposed for tests and for
  /// clearing transient key material on sensitive lifecycle events.
  @visibleForTesting
  static void clearKeyCache() {
    _keyCache.clear();
    _keyCacheOrder.clear();
  }

  static List<int> _randomNonce() => _randomBytes(12);

  static List<int> _randomBytes(int length) {
    final rng = Random.secure();
    return List<int>.generate(length, (_) => rng.nextInt(256));
  }
}

/// PIN hashing with versioned formats:
/// legacy `salt:hash` where hash = SHA-256(salt + pin)
/// v2 `v2:<iterations>:<saltB64>:<hashB64>` where hash = PBKDF2(pin, salt).
abstract final class PinHasher {
  /// Current PBKDF2 iterations for new hashes. Mutable for tests.
  /// Minimum 100,000 to prevent accidental weak hashing.
  static int pbkdf2Iterations = 210000;

  /// Floor for pbkdf2Iterations.
  static int minIterations = 100000;

  static Future<String> create(String pin) async {
    final iterations = pbkdf2Iterations < minIterations
        ? minIterations
        : pbkdf2Iterations;
    final salt = CryptoService.newSalt();
    final hash = await _pbkdf2Hash(salt, pin, iterations);
    return 'v2:$iterations:$salt:$hash';
  }

  static Future<bool> verify(String pin, String stored) async {
    if (stored.startsWith('v2:')) {
      final parts = stored.split(':');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 1) return false;
      final hash = await _pbkdf2Hash(parts[2], pin, iterations);
      return _constantTimeEquals(hash, parts[3]);
    }
    final parts = stored.split(':');
    if (parts.length != 2) return false;
    final hash = await _legacySha256Hash(parts[0], pin);
    return hash == parts[1];
  }

  static Future<String> _pbkdf2Hash(
    String salt,
    String pin,
    int iterations,
  ) async {
    final key = await CryptoService._deriveKeyCached(
      pin,
      salt,
      iterations,
    );
    return base64Encode(await key.extractBytes());
  }

  static Future<String> _legacySha256Hash(String salt, String pin) async {
    final digest = await Sha256().hash(utf8.encode('$salt:$pin'));
    return base64Encode(digest.bytes);
  }

  /// Length-independent comparison to avoid leaking the hash via timing.
  static bool _constantTimeEquals(String a, String b) {
    final aBytes = utf8.encode(a);
    final bBytes = utf8.encode(b);
    var diff = aBytes.length ^ bBytes.length;
    for (var i = 0; i < aBytes.length && i < bBytes.length; i++) {
      diff |= aBytes[i] ^ bBytes[i];
    }
    return diff == 0;
  }
}
