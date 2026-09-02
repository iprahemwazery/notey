import 'package:notey/features/notes/domain/entities/note.dart';

import 'crypto_service.dart';

/// Encrypts/decrypts a note's title & content with a user password.
/// Decrypted notes stay in memory only — the DB always holds ciphertext.
abstract final class NoteLockService {
  static Future<Note> lock(Note note, String password) async {
    final salt = CryptoService.newSalt();
    // PBKDF2 is by far the most expensive step of locking. Derive the key
    // once and encrypt BOTH fields with it — sharing one (password, salt)
    // means a lock runs a single derivation instead of two, halving lock
    // latency and making the lock spinner feel near-instant.
    final key = await CryptoService.deriveKeyForEncryption(
      password: password,
      salt: salt,
    );
    final encryptedTitle = await CryptoService.encryptField(
      plain: note.title,
      password: password,
      salt: salt,
      preKey: key,
    );
    final encryptedContent = await CryptoService.encryptField(
      plain: note.content,
      password: password,
      salt: salt,
      preKey: key,
    );
    return note.copyWith(
      title: encryptedTitle,
      content: encryptedContent,
      isLocked: true,
      lockSalt: salt,
    );
  }

  /// Throws when [password] is wrong (ciphertext won't authenticate).
  static Future<Note> unlock(Note note, String password) async {
    if (!note.isLocked || note.lockSalt == null) return note;
    final salt = note.lockSalt!;
    // Derive the PBKDF2 key once and reuse it for both fields — the KDF is by
    // far the most expensive step, so this halves unlock latency for locked
    // notes.
    final key = await CryptoService.deriveFieldKey(
      stored: note.title,
      password: password,
      salt: salt,
    );
    final title = await CryptoService.decryptFieldWithKey(
      stored: note.title,
      key: key,
    );
    String content;
    try {
      content = await CryptoService.decryptFieldWithKey(
        stored: note.content,
        key: key,
      );
    } on Object {
      // If the title authenticated, the password is correct — a content
      // failure can only mean its own KDF config differs from the title's
      // (legacy data). Validate against the content's own configuration
      // before giving up; a wrong password already surfaced on the title.
      content = await CryptoService.decryptField(
        stored: note.content,
        password: password,
        salt: salt,
      );
    }
    return note.copyWith(title: title, content: content);
  }

  /// [note] must already be decrypted in memory.
  static Future<Note> removeLock(Note note) async {
    return note.copyWith(isLocked: false, lockSalt: null);
  }
}
