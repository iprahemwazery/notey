import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Soft-deletes many notes by [ids] in a single transaction.
class BulkSoftDeleteNotes {
  BulkSoftDeleteNotes(this._repository);

  final NoteRepository _repository;

  Future<void> call(List<String> ids) => _repository.softDeleteAll(ids);
}
