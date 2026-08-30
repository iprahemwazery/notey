import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/vault_crypto.dart';

import 'package:notey/core/services/vault_key_service.dart';


/// Encrypts vault attachment files at rest.
///
/// Source files are sealed with the same AES-256-CBC+HMAC envelope used for
/// entry payloads (see [VaultCrypto]) and stored in the private `vault_files`
/// directory as `.enc` files. To view or share an attachment it is decrypted
/// into the OS temp directory and wiped right after — the database only ever
/// references opaque `.enc` paths, so vault files are unreadable even with
/// full disk access.
class VaultFileStore {
  VaultFileStore({
    VaultKeyService? keyService,
    Future<List<int>> Function()? rootKey,
  }) : _keyService = keyService,
       _rootKey = rootKey;

  final VaultKeyService? _keyService;
  final Future<List<int>> Function()? _rootKey;

  final Random _random = Random.secure();

  Future<List<int>> _keys() async {
    if (_rootKey != null) return _rootKey();
    return (_keyService ?? VaultKeyService()).get();
  }

  Future<Directory> _vaultDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, AppConstants.vaultFolder));
    await dir.create(recursive: true);
    return dir;
  }

  /// Reads [sourcePath], seals it end-to-end and returns the `.enc` absolute
  /// path. The plaintext source is left untouched (callers own its cleanup).
  Future<String> persistEncrypted(String sourcePath) async {
    final key = await _keys();
    final dir = await _vaultDir();
    final sourceExt = p.extension(sourcePath);
    final name =
        'vault_${DateTime.now().millisecondsSinceEpoch}_${_randomHex()}$sourceExt.enc';
    final target = p.join(dir.path, name);

    final bytes = await File(sourcePath).readAsBytes();
    final envelope = await VaultCrypto.encrypt(
      base64Encode(bytes),
      rootKey: key,
    );
    await File(target).writeAsString(envelope, flush: true);
    return target;
  }

  /// Decrypts an `.enc` attachment to the OS temp directory. Callers must wipe
  /// the returned file once done (see [disposeOf]).
  Future<String> decryptToTemp(String encPath) async {
    final key = await _keys();
    final envelope = await File(encPath).readAsString();
    final plain = await VaultCrypto.decrypt(envelope, rootKey: key);
    final bytes = base64Decode(plain);
    final dir = await getTemporaryDirectory();
    final stem = p.basenameWithoutExtension(encPath);
    final originalExt = p.extension(stem);
    final extension = originalExt.isNotEmpty ? originalExt : '.bin';
    final name =
        'vault_${DateTime.now().millisecondsSinceEpoch}_${_randomHex()}$extension';
    final temp = p.join(dir.path, name);
    await File(temp).writeAsBytes(bytes, flush: true);
    return temp;
  }

  /// Permanently removes an encrypted attachment from the vault store.
  Future<void> delete(String encPath) async {
    if (encPath.isEmpty) return;
    try {
      final file = File(encPath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort.
    }
  }

  /// Best-effort wipe of a decrypted temp file.
  static Future<void> disposeOf(String tempPath) async {
    if (tempPath.isEmpty) return;
    try {
      final file = File(tempPath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Best effort.
    }
  }

  String _randomHex() =>
      _random.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
}
