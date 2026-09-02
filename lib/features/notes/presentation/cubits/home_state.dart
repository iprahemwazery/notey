import 'package:equatable/equatable.dart';
import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/entities/note_search_result.dart';


enum SortMode { recent, oldest, color, custom }

enum ViewState { initial, loading, loaded }

class HomeState extends Equatable {
  final List<Note> notes;
  final ViewState viewState;
  final String query;
  final SortMode sortMode;
  final Set<String> selectedIds;
  final bool gridLayout;
  final String? activeTag;
  final String? activeFolder;
  final List<String> folders;
  final Map<String, int> customOrder;

  /// Advanced-search hits. Only populated while [isSearching].
  final List<NoteSearchMatch> searchResults;

  /// Recent search terms, newest first.
  final List<String> searchHistory;

  const HomeState({
    this.notes = const [],
    this.viewState = ViewState.initial,
    this.query = '',
    this.sortMode = SortMode.recent,
    this.selectedIds = const {},
    this.gridLayout = true,
    this.activeTag,
    this.activeFolder,
    this.folders = const [],
    this.customOrder = const {},
    this.searchResults = const [],
    this.searchHistory = const [],
  });

  bool get selectionMode => selectedIds.isNotEmpty;

  /// Whether the advanced-search mode is active.
  bool get isSearching => query.trim().isNotEmpty;

  List<Note> get sortedNotes {
    var list = List<Note>.of(notes);
    if (activeTag != null && activeTag!.isNotEmpty) {
      list = list.where((n) => n.tags.contains(activeTag)).toList();
    }
    switch (sortMode) {
      case SortMode.recent:
        list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortMode.oldest:
        list.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case SortMode.color:
        list.sort((a, b) => a.colorIndex.compareTo(b.colorIndex));
      case SortMode.custom:
        list.sort((a, b) {
          final ia = customOrder[a.id] ?? 0;
          final ib = customOrder[b.id] ?? 0;
          return ia.compareTo(ib);
        });
    }
    return list;
  }

  List<String> get allTags {
    final tags = <String>{};
    for (final note in notes) {
      tags.addAll(note.tags);
    }
    return tags.toList()..sort();
  }

  HomeState copyWith({
    List<Note>? notes,
    ViewState? viewState,
    String? query,
    SortMode? sortMode,
    Set<String>? selectedIds,
    bool? gridLayout,
    String? Function()? activeTag,
    String? Function()? activeFolder,
    List<String>? folders,
    Map<String, int>? customOrder,
    List<NoteSearchMatch>? searchResults,
    List<String>? searchHistory,
  }) {
    return HomeState(
      notes: notes ?? this.notes,
      viewState: viewState ?? this.viewState,
      query: query ?? this.query,
      sortMode: sortMode ?? this.sortMode,
      selectedIds: selectedIds ?? this.selectedIds,
      gridLayout: gridLayout ?? this.gridLayout,
      activeTag: activeTag != null ? activeTag() : this.activeTag,
      activeFolder: activeFolder != null ? activeFolder() : this.activeFolder,
      folders: folders ?? this.folders,
      customOrder: customOrder ?? this.customOrder,
      searchResults: searchResults ?? this.searchResults,
      searchHistory: searchHistory ?? this.searchHistory,
    );
  }

  @override
  List<Object?> get props => [
    notes,
    viewState,
    query,
    sortMode,
    selectedIds,
    gridLayout,
    activeTag,
    activeFolder,
    folders,
    customOrder,
    searchResults,
    searchHistory,
  ];
}
