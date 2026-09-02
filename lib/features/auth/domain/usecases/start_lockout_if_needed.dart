import 'package:notey/features/auth/domain/repositories/auth_lockout_repository.dart';

/// Starts a lockout window when `failedAttempts` breaches the policy, returning
/// the applied duration; `null` when no lockout should start.
class StartLockoutIfNeeded {
  StartLockoutIfNeeded(this._repository);

  final AuthLockoutRepository _repository;

  Future<Duration?> call({required int failedAttempts}) =>
      _repository.startLockoutIfNeeded(failedAttempts: failedAttempts);
}
