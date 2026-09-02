import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Persists a single updated [note] (e.g. toggling pin, changing color).
class UpdateNote {
  UpdateNote(this._repository);

  final NoteRepository _repository;

  Future<void> call(Note note) => _repository.update(note);
}
