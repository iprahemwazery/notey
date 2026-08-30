import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/features/auth/cubit/auth_cubit.dart';
import 'package:notey/features/auth/cubit/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    setUpCommon(prefs: <String, Object>{});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter/platform'),
      (MethodCall methodCall) async => null,
    );
  });

  group('AuthCubit — initialisation', () {
    testWidgets('emits choosing when no lock method is persisted',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        expect(cubit.state.phase, AuthPhase.choosing);
        await cubit.close();
      });
    });

    testWidgets('emits ready when method is none',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'appLockMethod': 'none',
        });
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.none);
        await cubit.close();
      });
    });

    testWidgets('emits unlocking when method is pin',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'appLockMethod': 'pin',
        });
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        expect(cubit.state.phase, AuthPhase.unlocking);
        expect(cubit.state.method, AppLockMethod.pin);
        await cubit.close();
      });
    });
  });

  group('AuthCubit — choosing', () {
    testWidgets('chooseDevice transitions to deviceSetup',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.chooseDevice();
        expect(cubit.state.phase, AuthPhase.deviceSetup);
        expect(cubit.state.method, AppLockMethod.device);
        await cubit.close();
      });
    });

    testWidgets('choosePassword transitions to passwordCreate',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();
        expect(cubit.state.phase, AuthPhase.passwordCreate);
        expect(cubit.state.method, AppLockMethod.pin);
        await cubit.close();
      });
    });

    testWidgets('chooseSkip sets method to none and emits ready',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        await cubit.chooseSkip();
        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.none);
        await cubit.close();
      });
    });
  });

  group('AuthCubit — password setup', () {
    testWidgets('4-digit PIN transitions from create to confirm',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();
        expect(cubit.state.phase, AuthPhase.passwordCreate);

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(cubit.state.phase, AuthPhase.passwordConfirm);
        expect(cubit.state.firstPinEntry, '1234');
        expect(cubit.state.pin, '');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('mismatched PIN shows error', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(cubit.state.phase, AuthPhase.passwordConfirm);

        for (final d in ['5', '6', '7', '8']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(cubit.state.error, 'pinMismatchError');
        expect(cubit.state.pin, '');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('matched PIN completes setup and emits biometric offer',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(cubit.state.phase, AuthPhase.passwordConfirm);

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        expect(cubit.state.phase, AuthPhase.biometricOffer);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 15)));

    testWidgets('backspace removes last digit', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        cubit.onPinDigit('1');
        cubit.onPinDigit('2');
        expect(cubit.state.pin, '12');

        cubit.onPinBackspace();
        expect(cubit.state.pin, '1');

        cubit.onPinBackspace();
        expect(cubit.state.pin, '');

        cubit.onPinBackspace();
        expect(cubit.state.pin, '');
        await cubit.close();
      });
    });

    testWidgets('more than 4 digits is ignored', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(cubit.state.phase, AuthPhase.passwordConfirm);
        expect(cubit.state.pin, '');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('AuthCubit — biometric offer', () {
    testWidgets('acceptBiometric transitions to backupPinCreate',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        expect(cubit.state.phase, AuthPhase.biometricOffer);

        cubit.acceptBiometric();
        expect(cubit.state.phase, AuthPhase.backupPinCreate);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 15)));

    testWidgets('skipBiometric completes setup with pin method',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        cubit.skipBiometric();
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.pin);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('AuthCubit — backup PIN setup', () {
    testWidgets('backup PIN confirm completes with biometric method',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        // Complete main PIN
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        // Accept biometric
        cubit.acceptBiometric();
        expect(cubit.state.phase, AuthPhase.backupPinCreate);

        // Enter backup PIN: 5678
        for (final d in ['5', '6', '7', '8']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(cubit.state.phase, AuthPhase.backupPinConfirm);

        // Confirm backup PIN
        for (final d in ['5', '6', '7', '8']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.biometric);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 25)));

    testWidgets('backup PIN mismatch shows error', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        cubit.acceptBiometric();
        expect(cubit.state.phase, AuthPhase.backupPinCreate);

        for (final d in ['5', '6', '7', '8']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(cubit.state.phase, AuthPhase.backupPinConfirm);

        for (final d in ['1', '1', '1', '1']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));

        expect(cubit.state.error, 'pinMismatchError');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 20)));
  });

  group('AuthCubit — unlock PIN verification', () {
    testWidgets('correct PIN emits ready', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        await lock.setPin('5678');
        await lock.setMethod(AppLockMethod.pin);

        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        expect(cubit.state.phase, AuthPhase.unlocking);

        await cubit.verifyPin('5678');
        await Future<void>.delayed(const Duration(seconds: 2));
        expect(cubit.state.phase, AuthPhase.ready);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('wrong PIN shows error', (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        await lock.setPin('5678');
        await lock.setMethod(AppLockMethod.pin);

        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();

        await cubit.verifyPin('1111');
        expect(cubit.state.phase, AuthPhase.unlocking);
        expect(cubit.state.error, 'wrongPin');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('unlock PIN digit and backspace work',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        await lock.setMethod(AppLockMethod.pin);

        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();

        cubit.onUnlockPinDigit('1');
        cubit.onUnlockPinDigit('2');
        expect(cubit.state.pin, '12');

        cubit.onUnlockPinBackspace();
        expect(cubit.state.pin, '1');
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('AuthCubit — device auth', () {
    testWidgets('authenticateDevice with success sets method to device',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.chooseDevice();
        expect(cubit.state.phase, AuthPhase.deviceSetup);

        await cubit.authenticateDevice();
        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.device);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('AuthCubit — biometric unlock', () {
    testWidgets('authenticateBiometric success emits ready',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'appLockMethod': 'biometric',
        });
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();

        cubit.emit(const AuthState(
          phase: AuthPhase.unlocking,
          method: AppLockMethod.biometric,
        ));
        await cubit.authenticateBiometric();
        expect(cubit.state.phase, AuthPhase.ready);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets('showPinFallback transitions to fallbackToPin',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();

        cubit.showPinFallback();
        expect(cubit.state.phase, AuthPhase.fallbackToPin);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('AuthCubit — goBackToChoosing', () {
    testWidgets('goBackToChoosing resets to choosing phase',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: AutoBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();
        expect(cubit.state.phase, AuthPhase.passwordCreate);

        cubit.goBackToChoosing();
        expect(cubit.state.phase, AuthPhase.choosing);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 10)));
  });

  group('AuthCubit — always-unavailable biometric', () {
    testWidgets('password setup without biometric goes straight to ready',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        final lock = AppLockController(secureStorage: FakeSecureStorage());
        await lock.init();
        final cubit = AuthCubit(
          lockController: lock,
          biometricService: _UnavailableBiometricService(),
        );
        await cubit.init();
        cubit.choosePassword();

        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 2));
        for (final d in ['1', '2', '3', '4']) {
        cubit.onPinDigit(d);
      }
        await Future<void>.delayed(const Duration(seconds: 3));

        expect(cubit.state.phase, AuthPhase.ready);
        expect(cubit.state.method, AppLockMethod.pin);
        await cubit.close();
      });
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}

class _UnavailableBiometricService implements BiometricService {
  @override
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  }) async =>
      BiometricResult.unavailable;

  @override
  Future<BiometricAvailability> getAvailability() async =>
      BiometricAvailability.unsupported;

  @override
  Future<bool> openBiometricsSettings() async => false;

  @override
  Future<void> stopAuthentication() async {}
}
