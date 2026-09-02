import 'package:notey/features/auth/data/datasources/auth_lockout_local_data_source.dart';
import 'package:notey/features/auth/domain/entities/lockout_policy.dart';
import 'package:notey/features/auth/domain/repositories/auth_lockout_repository.dart';

/// Concrete [AuthLockoutRepository] backed by [AuthLockoutLocalDataSource]
/// (SharedPreferences).
class AuthLockoutRepositoryImpl implements AuthLockoutRepository {
  AuthLockoutRepositoryImpl({
    AuthLockoutLocalDataSource? dataSource,
    LockoutPolicy policy = LockoutPolicy.defaultPolicy,
    DateTime Function()? now,
  })  : _dataSource = dataSource ?? AuthLockoutLocalDataSource(),
        _policy = policy,
        _now = now ?? DateTime.now;

  final AuthLockoutLocalDataSource _dataSource;
  final LockoutPolicy _policy;
  final DateTime Function() _now;

  @override
  LockoutPolicy get policy => _policy;

  @override
  Future<Duration?> remainingLockout() async {
    final until = await _dataSource.readLockoutUntil();
    if (until == null) return null;
    final remainingMs = until - _now().millisecondsSinceEpoch;
    if (remainingMs <= 0) {
      await _dataSource.clearAll();
      return null;
    }
    return Duration(milliseconds: remainingMs);
  }

  @override
  Future<int> recordFailedAttempt() async {
    final attempts = (await _dataSource.readAttempts()) + 1;
    await _dataSource.writeAttempts(attempts);
    return attempts;
  }

  @override
  Future<Duration?> startLockoutIfNeeded({required int failedAttempts}) async {
    if (failedAttempts < _policy.maxAttempts) return null;
    final until = _now().millisecondsSinceEpoch + _policy.lockoutSeconds * 1000;
    await _dataSource.writeLockoutUntil(until);
    await _dataSource.writeAttempts(0);
    return Duration(seconds: _policy.lockoutSeconds);
  }

  @override
  Future<void> clear() => _dataSource.clearAll();
}
