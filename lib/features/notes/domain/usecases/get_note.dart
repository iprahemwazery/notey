import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Reads a single note by [id]; `null` when it no longer exists.
class GetNote {
  GetNote(this._repository);

  final NoteRepository _repository;

  Future<Note?> call(String id) => _repository.getNote(id);
}