import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Locks a note with a password and persists it in a strictly sequential
/// pipeline: encrypt -> DB write -> return the persisted, fully-updated
/// entity. The DB always stores ciphertext; the returned note carries the
/// encrypted fields so callers never have to re-encrypt.
///
/// This is the single source of truth for the "lock this note" action. The
/// caller is responsible for supplying plaintext fields (the note it is
/// currently editing); if the note already exists it is [repository.update]d,
/// otherwise (brand-new note) it is inserted.
class LockNote {
  LockNote(this._repository);

  final NoteRepository _repository;

  /// Encrypts [note] with [password], writes it, and returns the locked note.
  ///
  /// [isNew] selects insert vs update; [updatedAt] gives the caller control
  /// over the persisted timestamp (defaults to now).
  Future<Note> call({
    required Note note,
    required String password,
    bool isNew = false,
    DateTime? updatedAt,
  }) async {
    var locked = await NoteLockService.lock(note, password);
    if (isNew) {
      await _repository.insert(locked);
    } else {
      final stamped = locked.copyWith(
        updatedAt: updatedAt ?? locked.updatedAt,
      );
      locked = stamped;
      await _repository.update(stamped);
    }
    return locked;
  }
}