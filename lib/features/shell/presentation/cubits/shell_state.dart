import 'package:equatable/equatable.dart';

import 'package:notey/features/shell/domain/entities/shell_tab.dart';

/// Holds the current shell navigation state: which tab is active, which
/// tabs have been visited (built) and the full tab configuration.
class ShellState extends Equatable {
  const ShellState({
    this.activeTabIndex = 0,
    this.visitedTabs = const <int>{0},
    this.tabs = const <ShellTab>[],
  });

  /// Index of the currently selected tab.
  final int activeTabIndex;

  /// Indices of tabs that have been visited (and whose widget state should
  /// be kept alive).
  final Set<int> visitedTabs;

  /// The full list of navigation tabs.
  final List<ShellTab> tabs;

  ShellState copyWith({
    int? activeTabIndex,
    Set<int>? visitedTabs,
    List<ShellTab>? tabs,
  }) {
    return ShellState(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      visitedTabs: visitedTabs ?? this.visitedTabs,
      tabs: tabs ?? this.tabs,
    );
  }

  @override
  List<Object?> get props => <Object?>[activeTabIndex, visitedTabs, tabs];
}
