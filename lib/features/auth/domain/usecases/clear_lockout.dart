import 'package:notey/features/auth/domain/repositories/auth_lockout_repository.dart';

/// Clears any persisted lockout and failed-attempt markers.
class ClearLockout {
  ClearLockout(this._repository);

  final AuthLockoutRepository _repository;

  Future<void> call() => _repository.clear();
}
