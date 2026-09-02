import 'package:shared_preferences/shared_preferences.dart';

import 'package:notey/features/onboarding/domain/repositories/onboarding_repository.dart';

/// SharedPreferences-backed [OnboardingRepository].
///
/// A deliberately thin implementation: it only reads/writes the persisted
/// completion flag and knows nothing about the onboarding UI.
class OnboardingRepositoryImpl implements OnboardingRepository {
  static const String _onboardingKey = 'onboardingDone';

  bool _done = false;
  bool _loaded = false;

  @override
  bool isDone() => _loaded && _done;

  @override
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _done = prefs.getBool(_onboardingKey) ?? false;
    _loaded = true;
  }

  @override
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
    _done = true;
    _loaded = true;
  }
}
