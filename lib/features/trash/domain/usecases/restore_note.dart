import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Restores a trashed [note] back to the main list and re-arms its reminder.
class RestoreNote {
  RestoreNote(this._repository);

  final TrashRepository _repository;

  Future<void> call(Note note) => _repository.restore(note);
}
