import 'package:flutter_test/flutter_test.dart';
import 'package:notey/features/auth/data/datasources/auth_lockout_local_data_source.dart';
import 'package:notey/features/auth/data/repositories_impl/auth_lockout_repository.dart';
import 'package:notey/features/auth/domain/entities/lockout_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;

  AuthLockoutRepositoryImpl build() => AuthLockoutRepositoryImpl(
        dataSource: AuthLockoutLocalDataSource(),
        now: () => now,
      );

  setUp(() {
    now = DateTime(2026, 1, 1, 12, 0, 0);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('AuthLockoutRepositoryImpl — policy', () {
    test('exposes the default policy', () {
      final repo = build();
      expect(repo.policy.maxAttempts, 5);
      expect(repo.policy.lockoutSeconds, 30);
    });

    test('LockoutPolicy equality', () {
      const a = LockoutPolicy.defaultPolicy;
      const b = LockoutPolicy.defaultPolicy;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.toString(), contains('maxAttempts: 5'));
    });
  });

  group('AuthLockoutRepositoryImpl — remainingLockout', () {
    test('returns null when never locked out', () async {
      final repo = build();
      expect(await repo.remainingLockout(), isNull);
    });

    test('returns remaining duration and clears an expired marker', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pin_lockout_until': now.millisecondsSinceEpoch - 1000,
      });
      final repo = build();
      expect(await repo.remainingLockout(), isNull);
      // expired marker wiped so a later read doesn't resurrect it
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(await repo.remainingLockout(), isNull);
    });

    test('returns a positive remaining duration while locked out', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pin_lockout_until': now.millisecondsSinceEpoch + 10000,
      });
      final repo = build();
      final remaining = await repo.remainingLockout();
      expect(remaining, isNotNull);
      expect(remaining!.inMilliseconds, 10000);
    });
  });

  group('AuthLockoutRepositoryImpl — attempts & lockout', () {
    test('records failed attempts incrementally', () async {
      final repo = build();
      expect(await repo.recordFailedAttempt(), 1);
      expect(await repo.recordFailedAttempt(), 2);
    });

    test('does not start a lockout below max attempts', () async {
      final repo = build();
      final lockout = await repo.startLockoutIfNeeded(failedAttempts: 4);
      expect(lockout, isNull);
    });

    test('starts a lockout and resets attempts at max attempts', () async {
      final repo = build();
      final lockout =
          await repo.startLockoutIfNeeded(failedAttempts: 5);
      expect(lockout, Duration(seconds: 30));
      // attempts were reset for the next cycle
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pin_failed_attempts'), 0);
      expect(prefs.getInt('pin_lockout_until'),
          now.millisecondsSinceEpoch + 30000);
    });

    test('clear removes all markers', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'pin_lockout_until': now.millisecondsSinceEpoch + 10000,
        'pin_failed_attempts': 3,
      });
      final repo = build();
      await repo.clear();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('pin_lockout_until'), isNull);
      expect(prefs.getInt('pin_failed_attempts'), isNull);
    });
  });
}
