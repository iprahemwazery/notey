import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Reads the configured retention window (in days) for the trash.
class GetTrashRetentionDays {
  GetTrashRetentionDays(this._repository);

  final TrashRepository _repository;

  Future<int> call() => _repository.retentionDays();
}
