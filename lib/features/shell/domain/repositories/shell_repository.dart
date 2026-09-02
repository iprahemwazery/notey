import 'package:notey/features/shell/domain/entities/shell_tab.dart';

/// Abstract interface for shell navigation persistence.
///
/// Concrete implementations live in the data layer.
abstract interface class ShellRepository {
  /// Returns the last active tab index (defaults to 0 on first launch).
  Future<int> getActiveTab();

  /// Persists the currently selected tab index.
  Future<void> setActiveTab(int index);

  /// Returns the full list of configured navigation tabs.
  List<ShellTab> getTabs();

  /// Resets the active tab to the default (Home, index 0).
  Future<void> resetToDefault();
}
