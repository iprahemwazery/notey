import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Removes the lock from an already-decrypted in-memory [Note] and persists
/// the plaintext version. Strictly sequential: unlock-in-memory -> DB write.
class RemoveNoteLock {
  RemoveNoteLock(this._repository);

  final NoteRepository _repository;

  Future<Note> call(Note decrypted) async {
    final plain = await NoteLockService.removeLock(decrypted);
    await _repository.update(plain);
    return plain;
  }
}