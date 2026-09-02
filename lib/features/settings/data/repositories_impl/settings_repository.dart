import 'package:notey/core/services/ui_prefs.dart';
import 'package:notey/features/settings/domain/repositories/settings_repository.dart';

/// SharedPreferences-backed [SettingsRepository] (via [UiPrefs]).
class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<double> readerFontScale() => UiPrefs.readerFontScale();

  @override
  Future<void> setReaderFontScale(double value) =>
      UiPrefs.setReaderFontScale(value);

  @override
  Future<int> trashRetentionDays() => UiPrefs.trashRetentionDays();

  @override
  Future<void> setTrashRetentionDays(int days) =>
      UiPrefs.setTrashRetentionDays(days);
}
