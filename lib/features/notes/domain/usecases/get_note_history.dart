import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

/// Returns history entries for a note, newest first.
class GetNoteHistory {
  GetNoteHistory(this._repository);

  final NoteHistoryRepository _repository;

  Future<List<NoteHistory>> call(String noteId) =>
      _repository.getHistory(noteId);
}
