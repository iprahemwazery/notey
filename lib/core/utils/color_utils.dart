import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Helpers for computing readable text colors over tinted backgrounds.
abstract final class ColorUtils {
  /// WCAG relative luminance (0..1) of a color, independent of the active
  /// theme. Never susceptible to a broken `estimateBrightnessForColor`
  /// threshold that yields white-on-light text in Light Mode.
  static double luminance(Color color) {
    double ch(double v) {
      return v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * ch(color.r) + 0.7152 * ch(color.g) + 0.0722 * ch(color.b);
  }

  /// WCAG contrast ratio between two colors (1..21).
  static double contrastRatio(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// The near-black color used for dark text on light backgrounds.
  static const Color darkText = Color(0xFF1E1E1E);

  /// Picks the text color that guarantees the highest readability on
  /// [background] by measuring the actual contrast ratio of both candidates
  /// instead of guessing from a luminance midpoint. This is what keeps deep
  /// brand tones readable while never washing white text out on mid/light
  /// tints (the root cause of the Light-Mode contrast bug).
  static Color foregroundOn(Color background) {
    final cWhite = Colors.white;
    final cDark = darkText;
    final contrastWhite = contrastRatio(background, cWhite);
    final contrastDark = contrastRatio(background, cDark);
    // Prefer white only when it is clearly more readable than dark text;
    // on ambiguous mid tones dark text wins so it never disappears in
    // Light Mode.
    return contrastWhite >= contrastDark ? cWhite : cDark;
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
