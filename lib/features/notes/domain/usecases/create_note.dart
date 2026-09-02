import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Persists a brand-new [note].
class CreateNote {
  CreateNote(this._repository);

  final NoteRepository _repository;

  Future<void> call(Note note) => _repository.insert(note);
}