import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Inserts many notes in a single transaction (used by backup import).
class InsertNotes {
  InsertNotes(this._repository);

  final NoteRepository _repository;

  Future<void> call(List<Note> notes) => _repository.insertAll(notes);
}