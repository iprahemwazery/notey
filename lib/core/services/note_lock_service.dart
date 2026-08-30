import 'package:notey/features/notes/model/note.dart';

import 'crypto_service.dart';

/// Encrypts/decrypts a note's title & content with a user password.
/// Decrypted notes stay in memory only — the DB always holds ciphertext.
abstract final class NoteLockService {
  static Future<Note> lock(Note note, String password) async {
    final salt = CryptoService.newSalt();
    final encryptedTitle = await CryptoService.encryptField(
      plain: note.title,
      password: password,
      salt: salt,
    );
    final encryptedContent = await CryptoService.encryptField(
      plain: note.content,
      password: password,
      salt: salt,
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
    final title = await CryptoService.decryptField(
      stored: note.title,
      password: password,
      salt: note.lockSalt!,
    );
    final content = await CryptoService.decryptField(
      stored: note.content,
      password: password,
      salt: note.lockSalt!,
    );
    return note.copyWith(title: title, content: content);
  }

  /// [note] must already be decrypted in memory.
  static Future<Note> removeLock(Note note) async {
    return note.copyWith(isLocked: false, lockSalt: null);
  }
}
