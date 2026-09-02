import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Permanently deletes the given trashed notes.
class PurgeNotes {
  PurgeNotes(this._repository);

  final TrashRepository _repository;

  Future<void> call(List<Note> notes) => _repository.purge(notes);
}
