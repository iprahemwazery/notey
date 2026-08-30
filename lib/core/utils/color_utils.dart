import 'package:flutter/material.dart';

/// Helpers for computing readable text colors over tinted backgrounds.
abstract final class ColorUtils {
  /// Main foreground color readable on the given background:
  /// white for deep colors, near-black for light tints.
  static Color foregroundOn(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1E1E1E);
  }

  /// Muted secondary foreground (for snippets, timestamps...).
  static Color foregroundMutedOn(Color background) =>
      foregroundOn(background).withValues(alpha: 0.72);

  /// Readable red used for destructive actions on tinted backgrounds.
  static Color dangerOn(Color background) {
    return foregroundOn(background) == Colors.white
        ? const Color(0xFFFF8A80)
        : const Color(0xFFC62828);
  }
}
