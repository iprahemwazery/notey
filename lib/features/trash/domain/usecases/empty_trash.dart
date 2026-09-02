import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Permanently deletes every trashed note.
class EmptyTrash {
  EmptyTrash(this._repository);

  final TrashRepository _repository;

  Future<void> call() => _repository.empty();
}
