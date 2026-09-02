import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// Reads all distinct non-empty folder names used by active notes.
class GetFolders {
  GetFolders(this._repository);

  final NoteRepository _repository;

  Future<List<String>> call() => _repository.getFolders();
}