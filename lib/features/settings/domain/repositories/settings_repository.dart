/// Port – repository exposing persisted app preferences surfaced in settings.
///
/// The presentation layer depends on this interface (never on the concrete
/// SharedPreferences implementation), keeping UI decoupled from storage. The
/// implementation lives in the data layer.
abstract interface class SettingsRepository {
  /// Reader font scale within the [UiPrefs]-defined range, `1.0` when unset.
  Future<double> readerFontScale();

  /// Persists [value], clamped to the supported range.
  Future<void> setReaderFontScale(double value);

  /// How long (in days) deleted notes stay in the trash before auto-purge.
  Future<int> trashRetentionDays();

  /// Persists the trash retention window in days.
  Future<void> setTrashRetentionDays(int days);
}
