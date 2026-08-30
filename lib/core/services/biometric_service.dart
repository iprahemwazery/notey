import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum BiometricResult { authenticated, unavailable, canceled }

enum BiometricAvailability { supported, noneEnrolled, unsupported }

/// Contract for the app-lock authentication, injectable for tests.
abstract class BiometricService {
  /// [deviceCredential] allows the device PIN/pattern fallback.
  /// [localizedReason] is shown by the OS on its auth dialog.
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  });

  /// Whether a fingerprint/face is enrolled on the device and usable by the app.
  Future<BiometricAvailability> getAvailability() async =>
      BiometricAvailability.supported;

  /// Tries to open the device's biometric-enrollment settings.
  /// Returns `false` when the platform can't open them (e.g. desktop).
  Future<bool> openBiometricsSettings() async => false;

  /// Actively cancels a native auth prompt that never resolved. Safe to call
  /// after a normal finish — it is a no-op then. Without this, a wedged
  /// BiometricPrompt keeps the flow on a perpetual spinner after its timeout.
  Future<void> stopAuthentication() async {}
}

/// Uses the device's own unlock mechanism (fingerprint, face or device PIN).
class DeviceBiometricService implements BiometricService {
  static const MethodChannel _channel = MethodChannel('notey/device');

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<BiometricResult> authenticate({
    bool deviceCredential = false,
    String? localizedReason,
  }) async {
    final bool supported;
    try {
      supported = await _auth.isDeviceSupported();
    } on MissingPluginException {
      // No platform implementation (e.g. desktop) — nothing to guard with.
      return BiometricResult.unavailable;
    } on Exception {
      return BiometricResult.canceled;
    }
    if (!supported) return BiometricResult.unavailable;

    try {
      final ok = await _auth.authenticate(
        localizedReason: localizedReason ?? 'Unlock Notey',
        biometricOnly: !deviceCredential,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricResult.authenticated : BiometricResult.canceled;
    } on Exception {
      return BiometricResult.canceled;
    } catch (_) {
      return BiometricResult.canceled;
    }
  }

  @override
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } on Exception {
      // Nothing to stop / plugin already released the prompt.
    }
  }

  @override
  Future<BiometricAvailability> getAvailability() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return BiometricAvailability.unsupported;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.noneEnrolled
          : BiometricAvailability.supported;
    } on MissingPluginException {
      return BiometricAvailability.unsupported;
    } on Exception {
      return BiometricAvailability.unsupported;
    }
  }

  @override
  Future<bool> openBiometricsSettings() async {
    try {
      final ok = await _channel.invokeMethod<bool>('openBiometricSettings');
      return ok ?? false;
    } on MissingPluginException {
      return false;
    } on Exception {
      return false;
    }
  }
}
