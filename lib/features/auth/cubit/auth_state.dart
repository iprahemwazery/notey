import 'package:equatable/equatable.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';


/// Phases of the authentication setup / unlock flow managed by [AuthCubit].
enum AuthPhase {
  /// App just started, reading persisted lock method.
  initial,

  /// User is choosing between device auth and password.
  choosing,

  /// Setting up device credential authentication (fingerprint/pattern/PIN).
  deviceSetup,

  /// Creating an app password (first entry).
  passwordCreate,

  /// Confirming the app password (second entry).
  passwordConfirm,

  /// Offering to add biometric on top of password.
  biometricOffer,

  /// Verifying biometric before enabling it.
  biometricVerifying,

  /// Creating a backup PIN (mandatory when biometric is added to password).
  backupPinCreate,

  /// Confirming the backup PIN.
  backupPinConfirm,

  /// Setup complete — ready to navigate to home.
  ready,

  /// Unlocking the app (lock screen).
  unlocking,

  /// Verifying PIN on lock screen.
  verifyingPin,

  /// An error occurred.
  error,

  /// Biometric/device auth unavailable, fallback to PIN.
  fallbackToPin,
}

/// Represents the current state of the auth cubit.
class AuthState extends Equatable {
  const AuthState({
    this.phase = AuthPhase.initial,
    this.method,
    this.pin = '',
    this.firstPinEntry,
    this.backupPin = '',
    this.firstBackupPinEntry,
    this.error = '',
    this.biometricAvailability,
    this.completed = false,
    this.lockedOut = false,
    this.remainingLockoutSeconds = 0,
    this.failedAttempts = 0,
  });

  final AuthPhase phase;
  final AppLockMethod? method;
  final String pin;
  final String? firstPinEntry;
  final String backupPin;
  final String? firstBackupPinEntry;
  final String error;
  final BiometricAvailability? biometricAvailability;
  final bool completed;
  final bool lockedOut;
  final int remainingLockoutSeconds;
  final int failedAttempts;

  bool get isSetup =>
      phase == AuthPhase.choosing ||
      phase == AuthPhase.deviceSetup ||
      phase == AuthPhase.passwordCreate ||
      phase == AuthPhase.passwordConfirm ||
      phase == AuthPhase.biometricOffer ||
      phase == AuthPhase.biometricVerifying ||
      phase == AuthPhase.backupPinCreate ||
      phase == AuthPhase.backupPinConfirm;

  bool get isUnlock => phase == AuthPhase.unlocking || phase == AuthPhase.verifyingPin;

  AuthState copyWith({
    AuthPhase? phase,
    AppLockMethod? method,
    String? pin,
    String? Function()? firstPinEntry,
    String? backupPin,
    String? Function()? firstBackupPinEntry,
    String? error,
    BiometricAvailability? biometricAvailability,
    bool? completed,
    bool? lockedOut,
    int? remainingLockoutSeconds,
    int? failedAttempts,
  }) {
    return AuthState(
      phase: phase ?? this.phase,
      method: method ?? this.method,
      pin: pin ?? this.pin,
      firstPinEntry: firstPinEntry != null ? firstPinEntry() : this.firstPinEntry,
      backupPin: backupPin ?? this.backupPin,
      firstBackupPinEntry:
          firstBackupPinEntry != null ? firstBackupPinEntry() : this.firstBackupPinEntry,
      error: error ?? this.error,
      biometricAvailability: biometricAvailability ?? this.biometricAvailability,
      completed: completed ?? this.completed,
      lockedOut: lockedOut ?? this.lockedOut,
      remainingLockoutSeconds:
          remainingLockoutSeconds ?? this.remainingLockoutSeconds,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    method,
    pin,
    firstPinEntry,
    backupPin,
    firstBackupPinEntry,
    error,
    biometricAvailability,
    completed,
    lockedOut,
    remainingLockoutSeconds,
    failedAttempts,
  ];
}
