import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Loads the trash list, auto-purging notes past the retention window first.
class LoadTrash {
  LoadTrash(this._repository);

  final TrashRepository _repository;

  Future<List<Note>> call() => _repository.load();
}
