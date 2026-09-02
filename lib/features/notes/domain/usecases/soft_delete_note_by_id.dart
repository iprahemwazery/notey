import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Soft-deletes a single note by [id] so it lands in the trash.
class SoftDeleteNoteById {
  SoftDeleteNoteById(this._repository);

  final NoteRepository _repository;

  Future<void> call(String id) => _repository.softDelete(id);
}
