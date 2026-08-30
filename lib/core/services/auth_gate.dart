import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/widgets/pin_widgets.dart';

import 'app_lock_controller.dart';
import 'auth_scope.dart';
import 'biometric_service.dart';
import 'haptics.dart';

/// Re-authenticates the user before a destructive (permanent) action.
///
/// Uses whichever lock method the app is configured with:
///  * no lock                 → always allowed
///  * device credential       → OS PIN/pattern/fingerprint prompt
///  * biometric (+PIN backup) → fingerprint prompt with a PIN fallback
///  * pin                     → 4-digit app PIN dialog
///
/// Returns `true` only when the user successfully authenticates.
abstract final class AuthGate {
  static Future<bool> require(
    BuildContext context, {
    String? reason,
  }) async {
    final scope = AuthScope.maybeOf(context);
    // No lock scope configured (e.g. widget tests) — allow freely.
    if (scope == null) return true;

    final lock = scope.lockController;
    if (!lock.initialized) await lock.init();

    final method = lock.method ?? AppLockMethod.none;
    if (method == AppLockMethod.none) return true;

    // Device credential authentication (fingerprint / face / device PIN).
    if (method == AppLockMethod.device) {
      final result = await scope.biometricService.authenticate(
        deviceCredential: true,
        localizedReason: reason,
      );
      if (result == BiometricResult.authenticated) return true;
      if (!context.mounted) return false;
      return _pinFallback(context, lock);
    }

    // Biometric primary (with PIN backup).
    if (method == AppLockMethod.biometric) {
      final availability = await scope.biometricService.getAvailability();
      if (availability == BiometricAvailability.supported) {
        final result = await scope.biometricService.authenticate(
          localizedReason: reason,
        );
        if (result == BiometricResult.authenticated) return true;
      }
      if (!context.mounted) return false;
      return _pinFallback(context, lock);
    }

    // PIN-only lock.
    if (!context.mounted) return false;
    return _pinFallback(context, lock);
  }

  /// Shows a 4-digit PIN dialog, returning true when it matches the app PIN.
  static Future<bool> _pinFallback(
    BuildContext context,
    AppLockController lock,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _PinAuthDialog(lock: lock, verify: lock.verifyPin),
        ) ??
        false;
  }
}

class _PinAuthDialog extends StatefulWidget {
  const _PinAuthDialog({required this.lock, required this.verify});

  final AppLockController lock;
  final Future<bool> Function(String pin) verify;

  @override
  State<_PinAuthDialog> createState() => _PinAuthDialogState();
}

class _PinAuthDialogState extends State<_PinAuthDialog> {
  String _pin = '';
  bool _wrong = false;
  bool _checking = false;

  void _onDigit(String d) {
    if (_checking || _pin.length >= 4) return;
    Haptics.tap();
    setState(() {
      _pin += d;
      _wrong = false;
    });
    if (_pin.length == 4) {
      _submit();
    }
  }

  void _onBackspace() {
    if (_checking) return;
    setState(() {
      if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      _wrong = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _checking = true);
    final ok = await widget.verify(_pin);
    if (!mounted) return;
    if (ok) {
      Haptics.light();
      Navigator.of(context).pop(true);
    } else {
      Haptics.heavy();
      setState(() {
        _checking = false;
        _pin = '';
        _wrong = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.enterAppPin),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(height: 12.h),
            PinDots(length: 4, entered: _checking ? 4 : _pin.length),
            SizedBox(height: 16.h),
            if (_wrong)
              Text(
                l10n.wrongPin,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (_checking)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: scheme.primary,
                  ),
                ),
              ),
            PinKeypad(
              onDigit: _checking ? (_) {} : _onDigit,
              onBackspace: _checking ? () {} : _onBackspace,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    );
  }
}
