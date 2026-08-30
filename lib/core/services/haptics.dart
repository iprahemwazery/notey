import 'package:flutter/services.dart';

/// Best-effort haptic feedback; silently ignored when unsupported (desktop).
abstract final class Haptics {
  static Future<void> tap() => _run(HapticFeedback.selectionClick);

  static Future<void> light() => _run(HapticFeedback.lightImpact);

  static Future<void> heavy() => _run(HapticFeedback.heavyImpact);

  static Future<void> _run(Future<void> Function() call) async {
    try {
      await call().timeout(const Duration(milliseconds: 300));
    } on Exception {
      // Not supported on this platform — ignore.
    } catch (_) {
      // Ignore.
    }
  }
}
