import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

/// Logs a new history snapshot for a note.
class LogNoteHistory {
  LogNoteHistory(this._repository);

  final NoteHistoryRepository _repository;

  Future<void> call(NoteHistory entry) => _repository.log(entry);
}
