import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Owns the vault's 256-bit root key.
///
/// The key is generated once with a secure RNG and stored exclusively in the
/// OS keychain / Android Keystore-backed [FlutterSecureStorage]. It never
/// touches the SQLite database or anywhere else on disk, so ciphertext cannot
/// be decrypted by pulling the DB alone. A process-local copy avoids decoding
/// the storage on every vault access.
class VaultKeyService {
  VaultKeyService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String storageKey = 'notey_vault_root_key';

  /// Process-wide cache so the OS-keychain read happens once per app session
  /// instead of on every vault access (speeds up opening/reopening the vault).
  static List<int>? _cache;

  final FlutterSecureStorage _storage;

  /// The 32-byte root key, generating and storing it on first use.
  Future<List<int>> get() async {
    final cached = _cache;
    if (cached != null) return cached;

    final stored = await _storage.read(key: storageKey);
    if (stored != null) {
      final decoded = base64Decode(stored);
      if (decoded.length == 32) {
        _cache = decoded;
        return decoded;
      }
    }

    final fresh = _randomBytes(32);
    await _storage.write(key: storageKey, value: base64Encode(fresh));
    _cache = fresh;
    return fresh;
  }

  /// True when a root key already exists (e.g. after first vault use).
  Future<bool> exists() async {
    if (_cache != null) return true;
    return await _storage.containsKey(key: storageKey);
  }

  void clearMemoryCache() => _cache = null;
}

List<int> _randomBytes(int length) {
  final random = Random.secure();
  final bytes = Uint8List(length);
  for (var i = 0; i < length; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}