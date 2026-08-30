import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide light/dark mode switch, persisted across restarts.
class ThemeController {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefKey = 'themeMode';

  final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  /// Loads the saved mode; falls back to [ThemeMode.system].
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      mode.value = ThemeMode.values.asNameMap()[raw] ?? ThemeMode.system;
    }
  }

  void toggle() {
    set(mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> set(ThemeMode value) async {
    mode.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, value.name);
    } on Exception {
      // Persistence is best-effort; the in-memory value is already applied.
    }
  }
}
