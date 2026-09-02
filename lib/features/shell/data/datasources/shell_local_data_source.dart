import 'package:shared_preferences/shared_preferences.dart';

/// Local data source for shell navigation state persistence.
///
/// Uses [SharedPreferences] to store and retrieve the last active
/// tab index so the app can restore it on the next cold start.
class ShellLocalDataSource {
  static const String _activeTabKey = 'shellActiveTab';

  /// Returns the last active tab index.
  ///
  /// Returns 0 (Home) when no value has been saved yet.
  Future<int> getActiveTab() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_activeTabKey) ?? 0;
  }

  /// Persists the active tab index.
  Future<void> saveActiveTab(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_activeTabKey, index);
  }

  /// Clears the saved active tab, resetting to the default (0).
  Future<void> clearActiveTab() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeTabKey);
  }
}
