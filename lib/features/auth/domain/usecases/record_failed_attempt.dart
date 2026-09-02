import 'package:notey/features/auth/domain/repositories/auth_lockout_repository.dart';

/// Persistently records a failed PIN attempt and returns the new attempt count.
class RecordFailedAttempt {
  RecordFailedAttempt(this._repository);

  final AuthLockoutRepository _repository;

  Future<int> call() => _repository.recordFailedAttempt();
}
