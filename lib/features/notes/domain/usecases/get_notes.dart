import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Loads the visible notes, optionally filtered by `folder`. Returns the
/// newest first.
class GetNotes {
  GetNotes(this._repository);

  final NoteRepository _repository;

  Future<List<Note>> call({String? folder}) =>
      _repository.getNotes(folder: folder);
}