import 'package:notey/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Loads the persisted onboarding completion flag into memory. Call once at
/// bootstrap so subsequent `isDone()` reads are synchronous and free of disk I/O.
class LoadOnboardingStatus {
  LoadOnboardingStatus(this._repository);

  final OnboardingRepository _repository;

  Future<bool> call() async {
    await _repository.load();
    return _repository.isDone();
  }
}
