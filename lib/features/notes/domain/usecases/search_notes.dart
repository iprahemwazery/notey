import 'package:notey/features/notes/domain/entities/note_search_result.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Advanced search across titles, bodies and attached text files. Each hit
/// carries the note plus where the match happened and a snippet.
class SearchNotes {
  SearchNotes(this._repository);

  final NoteRepository _repository;

  Future<List<NoteSearchMatch>> call({required String search, String? folder}) =>
      _repository.searchNotes(search: search, folder: folder);
}