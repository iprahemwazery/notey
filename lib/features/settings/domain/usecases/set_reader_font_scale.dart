import 'package:notey/features/settings/domain/repositories/settings_repository.dart';

/// Persists the reader (viewer) [value], clamped to the supported range.
class SetReaderFontScale {
  SetReaderFontScale(this._repository);

  final SettingsRepository _repository;

  Future<void> call(double value) => _repository.setReaderFontScale(value);
}
