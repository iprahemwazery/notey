import 'package:notey/features/settings/domain/repositories/settings_repository.dart';

/// Persists the trash retention window in days.
class SetTrashRetentionDays {
  SetTrashRetentionDays(this._repository);

  final SettingsRepository _repository;

  Future<void> call(int days) => _repository.setTrashRetentionDays(days);
}
