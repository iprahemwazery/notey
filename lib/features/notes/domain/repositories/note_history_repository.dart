import 'package:notey/features/notes/domain/entities/note_history.dart';

/// Port – repository for note edit history CRUD operations.
abstract interface class NoteHistoryRepository {
  /// Logs a new history snapshot for a note.
  Future<void> log(NoteHistory entry);

  /// Returns history entries for a note, newest first.
  Future<List<NoteHistory>> getHistory(String noteId);

  /// Deletes all history entries for a note.
  Future<void> deleteAll(String noteId);

  /// Deletes the oldest entries for a note, keeping at most [keep] snapshots.
  Future<void> trim(String noteId, {int keep = 30});
}
