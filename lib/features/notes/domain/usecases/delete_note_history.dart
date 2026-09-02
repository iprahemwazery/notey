import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

/// Deletes all history entries for a note.
class DeleteNoteHistory {
  DeleteNoteHistory(this._repository);

  final NoteHistoryRepository _repository;

  Future<void> call(String noteId) => _repository.deleteAll(noteId);
}
