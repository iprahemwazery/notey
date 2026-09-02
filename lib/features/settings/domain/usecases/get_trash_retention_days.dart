import 'package:notey/features/settings/domain/repositories/settings_repository.dart';

/// Reads how long (in days) deleted notes stay in the trash.
class GetTrashRetentionDays {
  GetTrashRetentionDays(this._repository);

  final SettingsRepository _repository;

  Future<int> call() => _repository.trashRetentionDays();
}
