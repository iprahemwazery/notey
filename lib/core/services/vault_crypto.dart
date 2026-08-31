import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;
import 'package:encrypt/encrypt.dart' as enc;

/// At-rest encryption for the digital vault.
///
/// Every payload is sealed with AES-256-CBC (PKCS#7) using a per-write random
/// IV plus an HMAC-SHA256 integrity tag over the IV+ciphertext. The root key
/// lives in the hardware-backed secure storage (see [VaultKeyService]); two
/// independent sub-keys are domain-separated from it for encryption and MAC,
/// so key-reuse across primitives is impossible.
///
/// All boxing/unboxing runs on a background isolate via [Isolate.run] to keep
/// the UI thread untouched — same policy as [CryptoService].
abstract final class VaultCrypto {
  static const int _ivLength = 16;

  static final Random _random = Random.secure();

  /// Cached domain-separated sub-keys keyed by a SHA-256 of the root key.
  /// The root key is stable per session, so re-deriving its two branches on
  /// every encrypt/decrypt call is pure waste. Because each branch is a
  /// SHA-256 output, the cache never holds the raw root key.
  static List<int>? _cachedEncKey;
  static List<int>? _cachedMacKey;
  static String? _cacheId;

  /// Returns the raw 32-byte enc+mac sub-keys for [rootKey], drawing on the
  /// process-wide cache when the same root key is reused across calls.
  static (Uint8List enc, Uint8List mac) _subKeys(List<int> rootKey) {
    final digest = c.sha256.convert(
      <int>[...utf8.encode('notey:vault:root:v1'), ...rootKey],
    );
    final id = base64Encode(Uint8List.fromList(digest.bytes));
    if (_cacheId == id && _cachedEncKey != null && _cachedMacKey != null) {
      return (Uint8List.fromList(_cachedEncKey!), Uint8List.fromList(_cachedMacKey!));
    }
    final branchEnc = branchKey(rootKey, 'notey:vault:enc:v1');
    final branchMac = branchKey(rootKey, 'notey:vault:mac:v1');
    _cachedEncKey = branchEnc;
    _cachedMacKey = branchMac;
    _cacheId = id;
    return (branchEnc, branchMac);
  }

  /// Clears the derived sub-key cache. Exposed for tests and sensitive
  /// lifecycle events (e.g. lock screen, sign out).
  static void clearCache() {
    _cachedEncKey = null;
    _cachedMacKey = null;
    _cacheId = null;
  }

  /// Seals [plain] as `ivBase64.cipherTextBase64.macBase64`.
  static Future<String> encrypt(String plain, {required List<int> rootKey}) {
    final iv = Uint8List.fromList(_randomBytes(_random, _ivLength));
    final (encKey, macKey) = _subKeys(rootKey);
    return Isolate.run<String>(() {
      final state = _DerivedKeys(encKey, macKey);
      final cipher = state.encrypter.encrypt(plain, iv: enc.IV(iv));
      final mac = state.mac(iv, cipher.bytes);
      return <String>[
        base64Encode(iv),
        base64Encode(cipher.bytes),
        base64Encode(mac),
      ].join('.');
    });
  }

  /// Opens an envelope. Throws [FormatException] on malformed or tampered data.
  static Future<String> decrypt(
    String envelope, {
    required List<int> rootKey,
  }) {
    final (encKey, macKey) = _subKeys(rootKey);
    return Isolate.run<String>(() {
      final state = _DerivedKeys(encKey, macKey);
      return _decryptWith(state, envelope);
    });
  }

  /// Opens many envelopes inside a **single** background isolate, returning the
  /// plaintext for each one (null when that row is malformed/tampered).
  ///
  /// Spawning one isolate for the whole batch — instead of one per envelope —
  /// keeps the vault fast and light on mobile, where `Isolate.run` per entry
  /// (especially when decrypted concurrently) can exhaust threads and crash.
  static Future<List<String?>> decryptBatch(
    List<String> envelopes, {
    required List<int> rootKey,
  }) {
    final (encKey, macKey) = _subKeys(rootKey);
    return Isolate.run<List<String?>>(() {
      final state = _DerivedKeys(encKey, macKey);
      return <String?>[
        for (final envelope in envelopes) _tryDecryptWith(state, envelope),
      ];
    });
  }

  static String _decryptWith(_DerivedKeys state, String envelope) {
    final parts = envelope.split('.');
    if (parts.length != 3) {
      throw const FormatException('Malformed vault envelope');
    }
    final iv = Uint8List.fromList(base64Decode(parts[0]));
    final cipherText = Uint8List.fromList(base64Decode(parts[1]));
    final mac = Uint8List.fromList(base64Decode(parts[2]));

    if (!_constantTimeEquals(state.mac(iv, cipherText), mac)) {
      throw const FormatException('Vault envelope failed integrity check');
    }
    return state.encrypter.decrypt(
      enc.Encrypted(cipherText),
      iv: enc.IV(iv),
    );
  }

  static String? _tryDecryptWith(_DerivedKeys state, String envelope) {
    try {
      return _decryptWith(state, envelope);
    } on FormatException {
      return null;
    }
  }
}

/// Derives a 32-byte domain-separated branch key via SHA-256.
/// Top-level so both [VaultCrypto] (main-thread cache) and tests can use it.
Uint8List branchKey(List<int> rootKey, String domain) {
  return Uint8List.fromList(
    c.sha256.convert(<int>[...utf8.encode(domain), ...rootKey]).bytes,
  );
}

/// Isolate-safe view of the two domain-separated sub-keys.
class _DerivedKeys {
  _DerivedKeys(Uint8List encKey, Uint8List macKey)
    : _encKey = encKey,
      _macKey = macKey;

  final Uint8List _encKey;
  final Uint8List _macKey;

  enc.Encrypter get encrypter =>
      enc.Encrypter(enc.AES(enc.Key(_encKey), mode: enc.AESMode.cbc));

  Uint8List mac(List<int> iv, List<int> cipherText) {
    final digester = c.Hmac(c.sha256, _macKey);
    return Uint8List.fromList(
      digester.convert(<int>[...iv, ...cipherText]).bytes,
    );
  }
}

/// Constant-time comparison to avoid length/timing side channels on the MAC.
bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

List<int> _randomBytes(Random random, int length) {
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}
