import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Updates many notes in a single transaction (bulk pin, color, reorder).
class BulkUpdateNotes {
  BulkUpdateNotes(this._repository);

  final NoteRepository _repository;

  Future<void> call(List<Note> notes) => _repository.updateAll(notes);
}
