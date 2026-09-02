import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

/// Trims a note's history backlog, keeping at most [keep] snapshots.
class TrimNoteHistory {
  TrimNoteHistory(this._repository);

  final NoteHistoryRepository _repository;

  Future<void> call(String noteId, {int keep = 30}) =>
      _repository.trim(noteId, keep: keep);
}
