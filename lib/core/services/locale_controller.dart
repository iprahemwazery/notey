import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide locale switch, persisted across restarts.
class LocaleController {
  LocaleController._();

  static final LocaleController instance = LocaleController._();

  static const String _prefKey = 'appLocale';

  final ValueNotifier<Locale> locale = ValueNotifier<Locale>(
    const Locale('ar'),
  );

  /// All supported locales.
  static const List<Locale> supported = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Loads the saved locale; falls back to Arabic.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null && supported.any((l) => l.languageCode == code)) {
      locale.value = Locale(code);
    }
  }

  Future<void> set(Locale value) async {
    locale.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, value.languageCode);
    } on Exception {
      // Persistence is best-effort.
    }
  }
}
