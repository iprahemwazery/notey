import 'package:notey/features/auth/domain/repositories/auth_lockout_repository.dart';

/// Reads the remaining app-lock lockout duration, or `null` when the user is
/// not currently locked out.
class GetRemainingLockout {
  GetRemainingLockout(this._repository);

  final AuthLockoutRepository _repository;

  Future<Duration?> call() => _repository.remainingLockout();
}
