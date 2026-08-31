import 'package:flutter/material.dart';

/// Central, type-safe access to the app theme so every screen resolves colors
/// and text styles from one consistent source instead of ad-hoc lookups.
///
/// All the helpers read from [Theme.of] and [ThemeData.colorScheme], so they
/// automatically flip between light and dark — guaranteeing a `Text`/`Icon`
/// that resolves through these extensions always uses the active mode.
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get scheme => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;

  /// True when the active theme is dark (never null-guessed from a hardcoded
  /// color — always reads the real brightness).
  bool get isDark => theme.brightness == Brightness.dark;

  /// Primary text color for the active mode.
  Color get onSurface => scheme.onSurface;

  /// Muted/secondary text color for the active mode.
  Color get mutedText => scheme.onSurfaceVariant;

  /// Helper/secondary description color for the active mode (guaranteed
  /// readable on [surfaceBackground]).
  Color get helperText => scheme.onSurfaceVariant;

  /// Scaffold background for the active mode.
  Color get surfaceBackground => theme.scaffoldBackgroundColor;

  /// Readable primary text color that follows the active theme brightness
  /// EXPLICITLY, without trusting `colorScheme.onSurface` (which can resolve
  /// to an unreadable value). Guarantees dark text in Light Mode and white
  /// text in Dark Mode.
  Color getAdaptiveTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black87
        : Colors.white;
  }

  /// Readable secondary/helper text color for the active brightness.
  /// Explicit and independent of `colorScheme`, so labels and captions never
  /// turn invisible against the (light) background.
  Color getAdaptiveMutedTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black54
        : Colors.white70;
  }

  /// A readable label color for a given [background] (white-ish text over
  /// brand-gradients, dark text over light cards).
  Color foregroundOn(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : scheme.onSurface;
}
