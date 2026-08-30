import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'auth_state.dart';

/// Manages the full authentication lifecycle: first-run setup + unlock gate.
///
/// Uses [AppLockController] for persistence and [BiometricService] for
/// biometric/device credential verification.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AppLockController lockController,
    required BiometricService biometricService,
  }) : _lock = lockController,
       _bio = biometricService,
       super(const AuthState());

  final AppLockController _lock;
  final BiometricService _bio;

  static const int _maxAttempts = 5;
  static const int _lockoutSeconds = 30;
  static const String _lockoutKey = 'pin_lockout_until';
  static const String _attemptsKey = 'pin_failed_attempts';

  /// Safety net for a native auth prompt that never resolves (driver issue or
  /// OS-level hang). Beyond this a prompt is treated exactly like a user
  /// cancellation so the lock/setup flow can never strand the app boot.
  static const Duration _authPromptTimeout = Duration(seconds: 45);
  static const Duration _availabilityTimeout = Duration(seconds: 10);

  Timer? _lockoutTimer;

  // ────────────────────── Initialisation ──────────────────────

  /// Read the persisted lock method and decide the initial phase.
  Future<void> init() async {
    if (!_lock.initialized) await _lock.init();
    if (isClosed) return;
    final method = _lock.method;

    if (method == null) {
      emit(state.copyWith(phase: AuthPhase.choosing));
    } else if (method == AppLockMethod.none) {
      emit(state.copyWith(phase: AuthPhase.ready, method: method));
    } else {
      await _startUnlock(method);
    }
  }

  Future<void> _startUnlock(AppLockMethod method) async {
    await _checkLockout();
    if (isClosed || state.lockedOut) return;

    if (method == AppLockMethod.pin) {
      emit(state.copyWith(phase: AuthPhase.unlocking, method: method));
    } else if (method == AppLockMethod.device) {
      emit(state.copyWith(phase: AuthPhase.unlocking, method: method));
      await authenticateDevice();
    } else {
      // biometric — try biometric first
      final availability = await _bio.getAvailability().timeout(
        _availabilityTimeout,
        onTimeout: () => BiometricAvailability.unsupported,
      );
      if (isClosed) return;
      if (availability == BiometricAvailability.supported) {
        emit(
          state.copyWith(
            phase: AuthPhase.unlocking,
            method: method,
            biometricAvailability: availability,
          ),
        );
        await authenticateBiometric();
      } else {
        // No biometric enrolled — check if backup PIN exists
        emit(
          state.copyWith(
            phase: AuthPhase.unlocking,
            method: method,
            biometricAvailability: availability,
          ),
        );
      }
    }
  }

  // ────────────────────── Setup: Choosing ──────────────────────

  /// Runs the native auth prompt under a hard watchdog. On timeout the erged
  /// prompt is actively cancelled (never left open) and the flow is treated as
  /// a user cancellation.
  Future<BiometricResult> _authenticateWithWatchdog({
    bool deviceCredential = false,
  }) async {
    try {
      return await _bio
          .authenticate(
            deviceCredential: deviceCredential,
            localizedReason: 'Unlock Notey',
          )
          .timeout(
            _authPromptTimeout,
            onTimeout: () => BiometricResult.canceled,
          );
    } finally {
      await _bio.stopAuthentication();
    }
  }

  /// Go back to the choosing phase.
  void goBackToChoosing() {
    emit(const AuthState(phase: AuthPhase.choosing));
  }

  /// User chose device credential authentication.
  void chooseDevice() {
    Haptics.tap();
    emit(
      state.copyWith(
        phase: AuthPhase.deviceSetup,
        method: AppLockMethod.device,
      ),
    );
  }

  /// User chose password-based authentication.
  void choosePassword() {
    Haptics.tap();
    emit(
      state.copyWith(
        phase: AuthPhase.passwordCreate,
        method: AppLockMethod.pin,
      ),
    );
  }

  /// User chose to skip locking entirely.
  Future<void> chooseSkip() async {
    Haptics.tap();
    await _lock.setMethod(AppLockMethod.none);
    emit(state.copyWith(phase: AuthPhase.ready, method: AppLockMethod.none));
  }

  // ────────────────────── Setup: Device ──────────────────────

  /// Verify device credentials and complete setup.
  Future<void> authenticateDevice() async {
    emit(state.copyWith(phase: AuthPhase.biometricVerifying, error: ''));
    final result = await _authenticateWithWatchdog(deviceCredential: true);
    if (isClosed) return;

    if (result == BiometricResult.authenticated) {
      debugPrint('TRACE_1: Biometric authentication returned SUCCESS');
      await Haptics.light();
      await _lock.setMethod(AppLockMethod.device);
      if (isClosed) return;
      emit(
        state.copyWith(phase: AuthPhase.ready, method: AppLockMethod.device),
      );
      debugPrint('TRACE_2: AuthCubit emitted Authenticated/Unlocked state');
    } else if (result == BiometricResult.unavailable) {
      emit(
        state.copyWith(
          phase: AuthPhase.error,
          error: 'Device credentials not available',
        ),
      );
    } else {
      await Haptics.heavy();
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: AuthPhase.deviceSetup,
          method: AppLockMethod.device,
          error: '',
        ),
      );
    }
  }

  // ────────────────────── Setup: Password / PIN ──────────────────────

  void onPinDigit(String d) {
    if (state.pin.length >= 4) return;
    final newPin = state.pin + d;
    emit(state.copyWith(pin: newPin, error: ''));

    if (newPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 160), () {
        if (isClosed) return;
        _onPinComplete(newPin);
      });
    }
  }

  void onPinBackspace() {
    if (state.pin.isEmpty) return;
    emit(
      state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
        error: '',
      ),
    );
  }

  Future<void> _onPinComplete(String pin) async {
    await Haptics.light();
    if (isClosed) return;

    if (state.phase == AuthPhase.passwordCreate) {
      // First entry — store and ask for confirmation
      emit(
        state.copyWith(
          phase: AuthPhase.passwordConfirm,
          firstPinEntry: () => pin,
          pin: '',
          error: '',
        ),
      );
    } else if (state.phase == AuthPhase.passwordConfirm) {
      // Second entry — verify match
      if (pin != state.firstPinEntry) {
        await Haptics.heavy();
        if (isClosed) return;
        emit(
          state.copyWith(
            pin: '',
            firstPinEntry: () => null,
            error: 'pinMismatchError',
          ),
        );
        return;
      }
      // Save the PIN
      await _lock.setPin(pin);
      if (isClosed) return;
      // Offer biometric enrollment
      final availability = await _bio.getAvailability();
      if (isClosed) return;

      if (availability == BiometricAvailability.supported) {
        emit(
          state.copyWith(
            phase: AuthPhase.biometricOffer,
            pin: '',
            firstPinEntry: () => null,
            error: '',
            biometricAvailability: availability,
          ),
        );
      } else {
        // No biometric available — complete setup
        await _lock.setMethod(AppLockMethod.pin);
        if (isClosed) return;
        emit(state.copyWith(phase: AuthPhase.ready, method: AppLockMethod.pin));
      }
    } else if (state.phase == AuthPhase.backupPinCreate) {
      // Backup PIN first entry
      emit(
        state.copyWith(
          phase: AuthPhase.backupPinConfirm,
          firstBackupPinEntry: () => pin,
          pin: '',
          backupPin: '',
          error: '',
        ),
      );
    } else if (state.phase == AuthPhase.backupPinConfirm) {
      // Backup PIN confirmation
      if (pin != state.firstBackupPinEntry) {
        await Haptics.heavy();
        if (isClosed) return;
        emit(
          state.copyWith(
            pin: '',
            backupPin: '',
            firstBackupPinEntry: () => null,
            error: 'pinMismatchError',
          ),
        );
        return;
      }
      // Save backup PIN (same storage as main PIN)
      await _lock.setPin(pin);
      if (isClosed) return;
      await _lock.setMethod(AppLockMethod.biometric);
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: AuthPhase.ready,
          method: AppLockMethod.biometric,
          pin: '',
        ),
      );
    }
  }

  // ────────────────────── Setup: Biometric Offer ──────────────────────

  void acceptBiometric() {
    Haptics.tap();
    emit(state.copyWith(phase: AuthPhase.backupPinCreate, error: ''));
  }

  void skipBiometric() async {
    Haptics.tap();
    await _lock.setMethod(AppLockMethod.pin);
    if (isClosed) return;
    emit(state.copyWith(phase: AuthPhase.ready, method: AppLockMethod.pin));
  }

  // ────────────────────── Unlock: Biometric ──────────────────────

  Future<void> authenticateBiometric() async {
    if (state.lockedOut) return;
    emit(state.copyWith(phase: AuthPhase.biometricVerifying, error: ''));

    final result = await _authenticateWithWatchdog();
    if (isClosed) return;

    if (result == BiometricResult.authenticated) {
      debugPrint('TRACE_1: Biometric authentication returned SUCCESS');
      await Haptics.light();
      if (isClosed) return;
      emit(state.copyWith(phase: AuthPhase.ready));
      debugPrint('TRACE_2: AuthCubit emitted Authenticated/Unlocked state');
    } else if (result == BiometricResult.unavailable) {
      // Biometric unavailable — show PIN fallback
      emit(state.copyWith(phase: AuthPhase.fallbackToPin, error: ''));
    } else {
      await Haptics.heavy();
      if (isClosed) return;
      emit(
        state.copyWith(phase: AuthPhase.unlocking, error: 'notRecognizedRetry'),
      );
    }
  }

  // ────────────────────── Unlock: PIN ──────────────────────

  Future<void> verifyPin(String pin) async {
    if (state.lockedOut) return;
    emit(state.copyWith(phase: AuthPhase.verifyingPin, error: ''));

    final ok = await _lock.verifyPin(pin);
    if (isClosed) return;

    if (ok) {
      await _clearLockout();
      await Haptics.light();
      if (isClosed) return;
      emit(state.copyWith(phase: AuthPhase.ready));
    } else {
      await _recordFailedAttempt();
      await Haptics.heavy();
      if (isClosed) return;
      emit(state.copyWith(phase: AuthPhase.unlocking, error: 'wrongPin'));
    }
  }

  void onUnlockPinDigit(String d) {
    if (state.pin.length >= 4 || state.lockedOut) return;
    final newPin = state.pin + d;
    emit(state.copyWith(pin: newPin, error: ''));

    if (newPin.length == 4) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (isClosed) return;
        verifyPin(newPin);
      });
    }
  }

  void onUnlockPinBackspace() {
    if (state.pin.isEmpty || state.lockedOut) return;
    emit(
      state.copyWith(
        pin: state.pin.substring(0, state.pin.length - 1),
        error: '',
      ),
    );
  }

  void showPinFallback() {
    emit(state.copyWith(phase: AuthPhase.fallbackToPin, pin: ''));
  }

  // ────────────────────── Lockout ──────────────────────

  Future<void> _checkLockout() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lockoutUntil = prefs.getInt(_lockoutKey);
    if (lockoutUntil == null) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockoutUntil) {
      _startLockoutTimer(lockoutUntil - now);
    } else {
      await prefs.remove(_lockoutKey);
      await prefs.remove(_attemptsKey);
    }
  }

  void _startLockoutTimer(int durationMs) {
    _lockoutTimer?.cancel();
    final seconds = (durationMs / 1000).ceil();
    emit(state.copyWith(lockedOut: true, remainingLockoutSeconds: seconds));
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final newSeconds = state.remainingLockoutSeconds - 1;
      if (newSeconds <= 0) {
        timer.cancel();
        _clearLockout();
        emit(
          state.copyWith(
            lockedOut: false,
            remainingLockoutSeconds: 0,
            phase: AuthPhase.unlocking,
            pin: '',
          ),
        );
      } else {
        emit(state.copyWith(remainingLockoutSeconds: newSeconds));
      }
    });
  }

  Future<void> _recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    await prefs.setInt(_attemptsKey, attempts);

    if (attempts >= _maxAttempts) {
      final lockoutUntil =
          DateTime.now().millisecondsSinceEpoch + (_lockoutSeconds * 1000);
      await prefs.setInt(_lockoutKey, lockoutUntil);
      await prefs.setInt(_attemptsKey, 0);
      _startLockoutTimer(_lockoutSeconds * 1000);
    } else {
      if (isClosed) return;
      emit(state.copyWith(failedAttempts: attempts));
    }
  }

  Future<void> _clearLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockoutKey);
    await prefs.remove(_attemptsKey);
    _lockoutTimer?.cancel();
  }

  @override
  Future<void> close() {
    _lockoutTimer?.cancel();
    return super.close();
  }
}
