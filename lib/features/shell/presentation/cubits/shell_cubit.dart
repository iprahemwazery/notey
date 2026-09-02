import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/features/shell/domain/entities/shell_tab.dart';
import 'package:notey/features/shell/domain/repositories/shell_repository.dart';
import 'package:notey/features/shell/domain/usecases/get_active_tab.dart';
import 'package:notey/features/shell/domain/usecases/get_tab_config.dart';
import 'package:notey/features/shell/domain/usecases/reset_to_default.dart';
import 'package:notey/features/shell/domain/usecases/set_active_tab.dart';

import 'shell_state.dart';

/// Drives shell navigation: restores the last active tab on cold start,
/// tracks visited tabs for lazy building and persists tab selections.
class ShellCubit extends Cubit<ShellState> {
  factory ShellCubit(ShellRepository repository) {
    final tabs = GetTabConfig(repository)();
    return ShellCubit._(
      getActiveTab: GetActiveTab(repository),
      setActiveTab: SetActiveTab(repository),
      resetToDefault: ResetToDefault(repository),
      tabs: tabs,
    );
  }

  ShellCubit._({
    required GetActiveTab getActiveTab,
    required SetActiveTab setActiveTab,
    required ResetToDefault resetToDefault,
    required List<ShellTab> tabs,
  }) : _getActiveTab = getActiveTab,
       _setActiveTab = setActiveTab,
       _resetToDefault = resetToDefault,
       super(ShellState(tabs: tabs));

  final GetActiveTab _getActiveTab;
  final SetActiveTab _setActiveTab;
  final ResetToDefault _resetToDefault;

  /// Loads the last active tab from persistence.
  ///
  /// The tab configuration is already available synchronously (via the
  /// factory), so the Home tab renders on the very first frame. Only the
  /// persisted selection is loaded here, in the background.
  Future<void> init() async {
    try {
      final initialIndex = await _getActiveTab();
      if (isClosed) return;
      emit(
        state.copyWith(
          activeTabIndex: initialIndex,
          visitedTabs: <int>{initialIndex},
        ),
      );
    } on Exception {
      if (isClosed) return;
      // Keep the default on read failure.
    }
  }

  /// Switches the active tab and persists the selection.
  ///
  /// The tab is marked as visited (so it gets built exactly once and its
  /// widget state is kept alive when switching away).
  void selectTab(int index) {
    if (index > state.tabs.length - 1) return;
    if (index == state.activeTabIndex) return;
    final visitedTabs = Set<int>.of(state.visitedTabs)..add(index);
    emit(
      state.copyWith(activeTabIndex: index, visitedTabs: visitedTabs),
    );
    unawaitedSafe(_setActiveTab(index));
  }

  /// Marks a tab as visited without changing the active selection.
  ///
  /// Used when a tab is opened through an external navigation path
  /// (e.g. a notification tap) so it gets built into the stack.
  void markVisited(int index) {
    if (index > state.tabs.length - 1) return;
    if (state.visitedTabs.contains(index)) return;
    final visitedTabs = Set<int>.of(state.visitedTabs)..add(index);
    emit(state.copyWith(visitedTabs: visitedTabs));
  }

  /// Resets the active tab to the default (Home) and clears persistence.
  Future<void> reset() async {
    await _resetToDefault();
    if (isClosed) return;
    emit(state.copyWith(activeTabIndex: 0, visitedTabs: <int>{0}));
  }

  void unawaitedSafe(Future<void> future) {
    future.ignore();
  }
}
