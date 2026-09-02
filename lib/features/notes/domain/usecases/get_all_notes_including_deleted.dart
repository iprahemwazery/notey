import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Reads every note including trashed ones (used by backup & orphan sweeps).
class GetAllNotesIncludingDeleted {
  GetAllNotesIncludingDeleted(this._repository);

  final NoteRepository _repository;

  Future<List<Note>> call() => _repository.getAllNotesIncludingDeleted();
}