import 'package:notey/features/auth/domain/entities/lockout_policy.dart';

/// Persistence + policy for app-lock brute-force protection (failed-PIN
/// attempts and the resulting lockout window).
///
/// This is the domain port for the lockout feature. Concrete persistence
/// (SharedPreferences) lives in the data layer.
abstract interface class AuthLockoutRepository {
  /// The brute-force protection policy in effect.
  LockoutPolicy get policy;

  /// The remaining lockout duration, or `null` when not currently locked out.
  Future<Duration?> remainingLockout();

  /// Persistently records a failed PIN attempt and returns the new attempt
  /// count.
  Future<int> recordFailedAttempt();

  /// Starts a lockout (persisting it) when `failedAttempts` breaches the
  /// policy, returning the applied lockout duration; returns `null` when no
  /// lockout should start.
  Future<Duration?> startLockoutIfNeeded({required int failedAttempts});

  /// Clears any persisted lockout and attempt markers.
  Future<void> clear();
}
