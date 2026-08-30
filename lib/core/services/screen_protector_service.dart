import 'package:flutter/services.dart';
import 'package:screen_protector/screen_protector.dart';

/// Safely toggles OS-level screen protection when sensitive vault content is
/// on screen.
///
/// [ScreenProtector.preventScreenshotOn] sets `FLAG_SECURE` on the window
/// (blocking screenshots & screen recording on Android) while
/// [ScreenProtector.protectDataLeakageOn] forces a blurred snapshot in the
/// app switcher so secrets never leak into the system recents.
///
/// Every call negotiates missing platform implementations (desktop, tests)
/// so the feature degrades to a no-op instead of crashing.
abstract final class ScreenProtectorService {
  static bool _protected = false;

  static bool get isProtected => _protected;

  static Future<void> protect() async {
    if (_protected) return;
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageOn();
      _protected = true;
    } on MissingPluginException {
      _protected = true; // Nothing to protect against — stay idempotent.
    } on Exception {
      _protected = true;
    }
  }

  static Future<void> unprotect() async {
    if (!_protected) return;
    _protected = false;
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
    } on MissingPluginException {
      // No-op.
    } on Exception {
      // No-op.
    }
  }
}