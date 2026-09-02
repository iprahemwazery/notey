import 'package:notey/features/settings/domain/repositories/backup_repository.dart';

/// Permanently wipes all app data (used by "Clear All Data").
class WipeAllData {
  WipeAllData(this._repository);

  final BackupRepository _repository;

  Future<void> call() => _repository.wipeAllData();
}
