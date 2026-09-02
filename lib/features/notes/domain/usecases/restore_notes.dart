import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Moves many trashed notes back to the main list in a single transaction.
class RestoreNotes {
  RestoreNotes(this._repository);

  final NoteRepository _repository;

  Future<void> call(List<String> ids) => _repository.restoreAll(ids);
}