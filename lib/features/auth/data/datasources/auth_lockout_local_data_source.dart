import 'package:shared_preferences/shared_preferences.dart';

/// Raw SharedPreferences I/O for the app-lock brute-force protection markers.
///
/// Owns the persisted keys and the expired-marker cleanup; the repository
/// layer interprets the raw values against the [LockoutPolicy].
class AuthLockoutLocalDataSource {
  AuthLockoutLocalDataSource({Future<SharedPreferences> Function()? prefs})
      : _prefs = prefs ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _prefs;

  /// Absolute epoch-ms until which the unlock flow is locked out, or `null`.
  Future<int?> readLockoutUntil() async {
    final prefs = await _prefs();
    return prefs.getInt(_lockoutKey);
  }

  /// Running consecutive failed-attempt count, or 0.
  Future<int> readAttempts() async {
    final prefs = await _prefs();
    return prefs.getInt(_attemptsKey) ?? 0;
  }

  Future<void> writeAttempts(int attempts) async {
    final prefs = await _prefs();
    await prefs.setInt(_attemptsKey, attempts);
  }

  Future<void> writeLockoutUntil(int epochMillis) async {
    final prefs = await _prefs();
    await prefs.setInt(_lockoutKey, epochMillis);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs();
    await prefs.remove(_lockoutKey);
    await prefs.remove(_attemptsKey);
  }

  static const String _lockoutKey = 'pin_lockout_until';
  static const String _attemptsKey = 'pin_failed_attempts';
}
