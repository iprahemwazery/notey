import 'package:notey/features/settings/domain/repositories/settings_repository.dart';

/// Reads the persisted reader (viewer) font scale.
class GetReaderFontScale {
  GetReaderFontScale(this._repository);

  final SettingsRepository _repository;

  Future<double> call() => _repository.readerFontScale();
}
