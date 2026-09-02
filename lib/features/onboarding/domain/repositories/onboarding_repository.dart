/// Abstract contract for the onboarding completion flag.
///
/// The presentation layer depends on this interface (never on the concrete
/// SharedPreferences implementation), keeping the UI decoupled from where/how
/// the flag is stored.
abstract interface class OnboardingRepository {
  /// Whether the user has already completed onboarding (`false` until [load]
  /// has populated state).
  bool isDone();

  /// Loads the persisted completion flag into memory.
  Future<void> load();

  /// Marks onboarding as completed.
  Future<void> complete();
}
