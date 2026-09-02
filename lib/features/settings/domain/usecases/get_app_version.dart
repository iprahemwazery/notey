import 'package:notey/features/settings/domain/repositories/backup_repository.dart';

/// Reads the installed app version string (e.g. `v1.2.3`).
class GetAppVersion {
  GetAppVersion(this._repository);

  final BackupRepository _repository;

  Future<String> call() => _repository.appVersion();
}
