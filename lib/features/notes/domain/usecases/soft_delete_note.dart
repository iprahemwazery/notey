import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Soft-deletes a note so it lands in the trash (restorable until purged).
class SoftDeleteNote {
  SoftDeleteNote(this._repository);

  final NoteRepository _repository;

  Future<void> call(Note note) => _repository.softDelete(note.id);
}
