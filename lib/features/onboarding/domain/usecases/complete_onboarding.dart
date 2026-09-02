import 'package:notey/features/onboarding/domain/repositories/onboarding_repository.dart';

/// Marks onboarding as completed so it is never shown again.
class CompleteOnboarding {
  CompleteOnboarding(this._repository);

  final OnboardingRepository _repository;

  Future<void> call() => _repository.complete();
}
