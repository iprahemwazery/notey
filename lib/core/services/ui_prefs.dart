import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Small persisted UI preferences (layout mode, reader text scale).
abstract final class UiPrefs {
  static const String _layoutKey = 'homeLayout';
  static const String _fontKey = 'readerFontScale';
  static const String _trashRetentionKey = 'trashRetentionDays';
  static const String _searchHistoryKey = 'searchHistory';

  static const String _onboardingKey = 'onboardingDone';

  /// How many recent search terms are kept in history.
  static const int maxSearchHistory = 10;

  static const double minFontScale = .85;
  static const double maxFontScale = 1.6;
  static const int defaultRetentionDays = 30;

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<bool> isGridLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_layoutKey) != 'list';
  }

  static Future<void> setGridLayout(bool grid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_layoutKey, grid ? 'grid' : 'list');
  }

  static Future<double> readerFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_fontKey);
    if (v == null) return 1;
    return v.clamp(minFontScale, maxFontScale);
  }

  static Future<void> setReaderFontScale(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontKey, value.clamp(minFontScale, maxFontScale));
  }

  static Future<int> trashRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_trashRetentionKey) ?? defaultRetentionDays;
  }

  static Future<void> setTrashRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_trashRetentionKey, days);
  }

  static Future<List<String>> loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_searchHistoryKey);
    if (raw == null || raw.isEmpty) return const <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } on FormatException {
      // Corrupt history — start fresh.
    } on TypeError {
      // Wrong JSON shape — start fresh.
    }
    return const <String>[];
  }

  static Future<void> saveSearchHistory(List<String> terms) async {
    final prefs = await SharedPreferences.getInstance();
    if (terms.isEmpty) {
      await prefs.remove(_searchHistoryKey);
      return;
    }
    final kept = terms.take(maxSearchHistory).toList();
    await prefs.setString(_searchHistoryKey, jsonEncode(kept));
  }
}
