import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/core/services/error_logger.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/features/notes/model/note.dart';

import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState());

  /// Safety net for the post-unlock race: an unresponsive DB read must never
  /// strand the home screen on its loading spinner. Oversized vs. any real
  /// query, tiny vs. an eternal hang.
  static const Duration _readTimeout = Duration(seconds: 4);

  final NoteRepository _repository;
  Timer? _searchDebounce;

  void _safeEmit(HomeState newState) {
    if (!isClosed) emit(newState);
  }

  Future<void> load() async {
    debugPrint('TRACE_5: HomeCubit.load() STARTED');
    _safeEmit(state.copyWith(viewState: ViewState.loading));
    try {
      final folders = await _repository
          .getFolders()
          .timeout(
            _readTimeout,
            onTimeout: () => throw TimeoutException('folders read timed out'),
          );
      if (isClosed) return;
      if (state.isSearching) {
        final results = await _repository
            .searchNotes(
              search: state.query,
              folder: state.activeFolder,
            )
            .timeout(
              _readTimeout,
              onTimeout: () =>
                  throw TimeoutException('search read timed out'),
            );
        if (isClosed) return;
        debugPrint('TRACE_6: search query returned ${results.length} hits');
        _safeEmit(
          state.copyWith(
            notes: results.map((r) => r.note).toList(),
            searchResults: results,
            viewState: ViewState.loaded,
            folders: folders,
          ),
        );
        debugPrint('TRACE_7: HomeCubit emitted HomeLoaded');
      } else {
        final notes = await _repository
            .getNotes(folder: state.activeFolder)
            .timeout(
              _readTimeout,
              onTimeout: () => throw TimeoutException('notes read timed out'),
            );
        if (isClosed) return;
        debugPrint('TRACE_6: Database query returned ${notes.length} notes');
        _safeEmit(
          state.copyWith(
            notes: notes,
            searchResults: const [],
            viewState: ViewState.loaded,
            folders: folders,
          ),
        );
        debugPrint('TRACE_7: HomeCubit emitted HomeLoaded');
      }
    } on TimeoutException catch (e, trace) {
      ErrorLogger.log('HomeCubit.load timed out: $e\n$trace');
      if (isClosed) return;
      // Never strand the UI on HomeLoading — fall back to an empty (still
      // usable) home instead of an eternal spinner.
      _safeEmit(state.copyWith(viewState: ViewState.loaded));
    } on Exception catch (e, trace) {
      ErrorLogger.log('HomeCubit.load failed: $e\n$trace');
      if (isClosed) return;
      _safeEmit(state.copyWith(viewState: ViewState.loaded));
    }
  }

  void onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (isClosed) return;
      _safeEmit(state.copyWith(query: value));
      recordSearchTerm(value);
      load();
    });
  }

  /// Records a committed search term into history (dedupe + live typing
  /// merge) capped at [UiPrefs.maxSearchHistory]. Terms shorter than three
  /// characters are ignored — they produce too many/too imprecise hits.
  void recordSearchTerm(String value) {
    final term = value.trim();
    if (term.length < 3) return;
    final list = List<String>.of(state.searchHistory);
    list.removeWhere((t) => t.toLowerCase() == term.toLowerCase());
    if (list.isNotEmpty && _isSameSearch(list.first, term)) {
      // Replaces partial terms while the user keeps typing.
      list[0] = term;
    } else {
      list.insert(0, term);
    }
    while (list.length > UiPrefs.maxSearchHistory) {
      list.removeLast();
    }
    _safeEmit(state.copyWith(searchHistory: list));
    unawaited(UiPrefs.saveSearchHistory(list));
  }

  static bool _isSameSearch(String a, String b) {
    final la = a.toLowerCase();
    final lb = b.toLowerCase();
    return la.startsWith(lb) || lb.startsWith(la);
  }

  Future<void> removeSearchHistory(String term) async {
    final list = List<String>.of(state.searchHistory)
      ..removeWhere((t) => t.toLowerCase() == term.toLowerCase());
    _safeEmit(state.copyWith(searchHistory: list));
    await UiPrefs.saveSearchHistory(list);
  }

  Future<void> clearSearchHistory() async {
    _safeEmit(state.copyWith(searchHistory: const []));
    await UiPrefs.saveSearchHistory(const <String>[]);
  }

  Future<void> loadSearchHistory() async {
    final history = await UiPrefs.loadSearchHistory();
    if (isClosed) return;
    _safeEmit(state.copyWith(searchHistory: history));
  }

  void setSort(SortMode mode) {
    _safeEmit(state.copyWith(sortMode: mode));
  }

  void toggleGridLayout() {
    _safeEmit(state.copyWith(gridLayout: !state.gridLayout));
  }

  void setActiveTag(String? tag) {
    _safeEmit(state.copyWith(activeTag: () => tag));
  }

  void setActiveFolder(String? folder) {
    _safeEmit(state.copyWith(activeFolder: () => folder));
    load();
  }

  void enterSelection(Note note) {
    _safeEmit(state.copyWith(selectedIds: {...state.selectedIds, note.id}));
  }

  void toggleSelection(Note note) {
    final ids = Set<String>.of(state.selectedIds);
    if (ids.contains(note.id)) {
      ids.remove(note.id);
    } else {
      ids.add(note.id);
    }
    _safeEmit(state.copyWith(selectedIds: ids));
  }

  void clearSelection() {
    _safeEmit(state.copyWith(selectedIds: {}));
  }

  void selectAll() {
    final allIds = state.sortedNotes.map((n) => n.id).toSet();
    _safeEmit(state.copyWith(selectedIds: allIds));
  }

  Future<void> togglePin(String id) async {
    final note = state.notes.cast<Note?>().firstWhere(
      (n) => n?.id == id,
      orElse: () => null,
    );
    if (note == null) return;
    await _repository.update(note.copyWith(pinned: !note.pinned));
    await load();
  }

  Future<void> softDelete(String id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> deleteSelected() async {
    await _repository.softDeleteAll(state.selectedIds.toList());
    _safeEmit(state.copyWith(selectedIds: {}));
    await load();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    final notes = List<Note>.of(state.sortedNotes);
    if (oldIndex < newIndex) newIndex -= 1;
    final item = notes.removeAt(oldIndex);
    notes.insert(newIndex, item);

    // Persist new order by assigning sequential sort values.
    final order = <String, int>{};
    for (var i = 0; i < notes.length; i++) {
      order[notes[i].id] = i;
    }

    // Update all notes with new sort order in one batch.
    final updated = notes.asMap().entries.map((e) {
      return e.value.copyWith(updatedAt: DateTime.now());
    }).toList();
    await _repository.updateAll(updated);

    _safeEmit(state.copyWith(sortMode: SortMode.custom, customOrder: order));
    await load();
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }
}
