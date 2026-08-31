import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/theme/theme_extensions.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/services/global_snackbar.dart';

import 'package:notey/core/services/haptics.dart';
import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/share_receiver.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/data/repositories/secure_vault_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';

import 'package:notey/features/notes/model/note_search_result.dart';

import 'package:notey/features/notes/cubit/home_cubit.dart';

import 'package:notey/features/notes/cubit/home_state.dart';

import 'package:notey/features/notes/view/widgets/color_picker_widget.dart';

import 'package:notey/features/notes/view/widgets/header_widget.dart';

import 'package:notey/features/notes/view/widgets/search_history_panel.dart';

import 'package:notey/features/notes/view/widgets/search_results_list.dart';

import 'package:notey/features/notes/view/widgets/selection_bar_widget.dart';

import 'package:notey/features/notes/view/widgets/selection_header_widget.dart';

import 'package:notey/features/notes/view/widgets/sort_menu_widget.dart';

import 'package:notey/features/notes/view/widgets/tag_filter_row.dart';

import 'package:notey/features/notes/view/widgets/folder_filter_row.dart';

import 'package:notey/widgets/empty_state.dart';

import 'package:notey/widgets/note_card.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'package:notey/app.dart' show noteyNavigatorKey;
import 'package:notey/features/notes/view/note_editor_screen.dart';

import 'package:notey/features/settings/view/settings_screen.dart';

import 'package:notey/features/trash/view/trash_screen.dart';

import 'package:notey/features/vault/view/vault_screen.dart';

import 'package:notey/features/notes/view/note_view_screen.dart';

/// Home screen: shows the notes grid + search + add/edit/pin/delete actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.repository,
    this.lockController,
    this.biometricService,
  });

  final NoteRepository? repository;
  final AppLockController? lockController;
  final BiometricService? biometricService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NoteRepository _repository = widget.repository ?? NoteRepository();
  late final AppLockController? _lockController = widget.lockController;
  late final BiometricService? _biometricService = widget.biometricService;
  final ImageStore _imageStore = ImageStore();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<bool> _searchFocused = ValueNotifier<bool>(false);
  bool _sweepDone = false;

  @override
  void initState() {
    super.initState();
    debugPrint('TRACE_4: HomeScreen initState called');
    ReminderService.onOpenNote = _openFromReminder;
    ShareReceiver.onShare = _openSharedInEditor;
    unawaited(ShareReceiver.init());
    _drainPendingReminders();
    _searchFocusNode.addListener(_onSearchFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The app arrived here right after a biometric/PIN unlock. Let the
      // remaining dismissal frames + platform channels settle BEFORE touching
      // the database — the exact point where the post-unlock freeze used to
      // wedge the main isolate between the unlock result and SQLite.
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        final bootStart = DateTime.now();
        context.read<HomeCubit>().load().whenComplete(() {
          if (kDebugMode) {
            print(
              '[boot] home notes loaded '
              '+${DateTime.now().difference(bootStart).inMilliseconds}ms',
            );
          }
        });
        context.read<HomeCubit>().loadSearchHistory();
      });
      UiPrefs.isGridLayout().then((grid) {
        if (mounted && grid != context.read<HomeCubit>().state.gridLayout) {
          context.read<HomeCubit>().toggleGridLayout();
        }
      });
    });
  }

  // Focus changes only drive the search-history panel visibility, so a
  // [ValueNotifier] + local builder is enough — no full-page setState.
  void _onSearchFocusChanged() {
    _searchFocused.value = _searchFocusNode.hasFocus;
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _searchController.dispose();
    _searchFocused.dispose();
    super.dispose();
  }

  NoteSort _sortModeToNoteSort(SortMode mode) => switch (mode) {
    SortMode.recent => NoteSort.recent,
    SortMode.oldest => NoteSort.oldest,
    SortMode.color => NoteSort.color,
    SortMode.custom => NoteSort.custom,
  };

  SortMode _noteSortToSortMode(NoteSort sort) => switch (sort) {
    NoteSort.recent => SortMode.recent,
    NoteSort.oldest => SortMode.oldest,
    NoteSort.color => SortMode.color,
    NoteSort.custom => SortMode.custom,
  };

  Future<void> _drainPendingReminders() async {
    final List<String> ids = ReminderService.takePendingNoteIds();
    for (final String id in ids) {
      await _openFromReminder(id);
    }
  }

  Future<void> _openFromReminder(String noteId) async {
    final Note? note = await _repository.getNote(noteId);
    if (note == null || note.deletedAt != null) return;
    final BuildContext? navContext = noteyNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;
    unawaited(
      Navigator.of(navContext).push(
        MaterialPageRoute<void>(
          builder: (_) => NoteViewScreen(note: note, repository: _repository),
        ),
      ),
    );
  }

  Future<void> _load() async {
    await context.read<HomeCubit>().load();
    await _sweepOrphanImagesOnce();
  }

  Future<void> _sweepOrphanImagesOnce() async {
    if (_sweepDone) return;
    _sweepDone = true;
    _runBackgroundSweep();
  }

  Future<void> _runBackgroundSweep() async {
    try {
      final all = await _repository.getAllNotesIncludingDeleted();
      final referenced = <String>{for (final note in all) ...note.attachments};
      await _imageStore.sweep(referenced);
    } on Exception {
      // Non-critical background task
    }
  }

  Future<void> _toggleLayout() async {
    await Haptics.tap();
    if (!mounted) return;
    context.read<HomeCubit>().toggleGridLayout();
    final grid = context.read<HomeCubit>().state.gridLayout;
    await UiPrefs.setGridLayout(grid);
  }

  Future<void> _openEditor([Note? note]) async {
    if (note != null) {
      await Haptics.tap();
      if (!mounted) return;
    }
    if (note != null && note.isLocked) {
      final l10n = AppLocalizations.of(context);
      final password = await showPasswordDialog(
        context,
        title: l10n.lockedNote,
        message: l10n.unlockDialogMessage,
        confirmButtonLabel: l10n.unlockConfirm,
      );
      if (password == null) return;
      try {
        final unlocked = await NoteLockService.unlock(note, password);
        if (!mounted) return;
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => NoteEditorScreen(
              note: unlocked,
              repository: _repository,
              unlockPassword: password,
            ),
          ),
        );
        if (changed == true) _load();
      } on Exception {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).wrongPasswordToast),
          ),
        );
      }
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NoteEditorScreen(note: note, repository: _repository),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _openSharedInEditor(SharedPayload payload) async {
    final List<String> persisted = <String>[];
    for (final String path in payload.paths) {
      try {
        final file = File(path);
        persisted.add(
          path.toLowerCase().endsWith('.png') ||
                  path.toLowerCase().endsWith('.jpg') ||
                  path.toLowerCase().endsWith('.jpeg') ||
                  path.toLowerCase().endsWith('.webp') ||
                  path.toLowerCase().endsWith('.gif')
              ? await _imageStore.persist(XFile(file.path))
              : await _imageStore.persistDocument(XFile(file.path)),
        );
      } on Exception {
        // Skip unreadable shared files.
      }
    }
    if (!mounted) return;
    final bool changed =
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => NoteEditorScreen(repository: _repository),
          ),
        ) ??
        false;
    if (changed) _load();
  }

  Future<void> _openViewer(Note note) async {
    await Haptics.tap();
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NoteViewScreen(
          note: note,
          repository: _repository,
          imageStore: _imageStore,
        ),
      ),
    );
    if (mounted &&
        (changed == true ||
            note.isLocked != (await _repository.getNote(note.id))?.isLocked)) {
      _load();
    }
  }

  Future<void> _openSettings() async {
    final controller = _lockController;
    final biometrics = _biometricService;
    if (controller == null || biometrics == null) return;
    await Haptics.tap();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          repository: _repository,
          lockController: controller,
          biometricService: biometrics,
        ),
      ),
    );
  }

  Future<void> _openVault() async {
    await Haptics.tap();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VaultScreen(repository: SecureVaultRepository()),
      ),
    );
  }

  Future<void> _openTrash() async {
    await Haptics.tap();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            TrashScreen(repository: _repository, imageStore: _imageStore),
      ),
    );
    if (mounted) _load();
  }

  void _onSearchChanged(String value) {
    context.read<HomeCubit>().onSearchChanged(value);
  }

  void _searchSubmitted(String value) {
    final cubit = context.read<HomeCubit>();
    if (value.trim().length >= 3) cubit.recordSearchTerm(value);
    _searchFocusNode.unfocus();
  }

  void _applySearchTerm(String term) {
    _searchController.text = term;
    _searchController.selection = TextSelection.collapsed(offset: term.length);
    _onSearchChanged(term);
    _searchFocusNode.requestFocus();
  }

  void _clearSearchWidget() {
    _searchController.clear();
    final cubit = context.read<HomeCubit>();
    if (cubit.state.query.isNotEmpty) _onSearchChanged('');
    _searchFocusNode.unfocus();
  }

  void _openSearchResult(NoteSearchMatch result) {
    _searchFocusNode.unfocus();
    unawaited(_openViewer(result.note));
  }

  Future<void> _togglePin(Note note) async {
    await Haptics.tap();
    if (!mounted) return;
    await context.read<HomeCubit>().togglePin(note.id);
  }

  void _enterSelection(Note note) {
    Haptics.heavy();
    context.read<HomeCubit>().enterSelection(note);
  }

  void _toggleSelection(Note note) {
    Haptics.tap();
    context.read<HomeCubit>().toggleSelection(note);
  }

  void _clearSelection() => context.read<HomeCubit>().clearSelection();

  void _selectAll() {
    Haptics.tap();
    final cubit = context.read<HomeCubit>();
    if (cubit.state.selectedIds.length == cubit.state.notes.length) {
      cubit.clearSelection();
    } else {
      cubit.selectAll();
    }
  }

  List<Note> _selectedNotesList() {
    final cubit = context.read<HomeCubit>();
    return cubit.state.notes
        .where((n) => cubit.state.selectedIds.contains(n.id))
        .toList();
  }

  Future<void> _bulkTogglePin() async {
    final targets = _selectedNotesList();
    if (targets.isEmpty) return;
    final pinTarget = targets.any((n) => !n.pinned);
    Haptics.tap();
    await _repository.updateAll(
      targets.map((n) => n.copyWith(pinned: pinTarget)).toList(),
    );
    await _load();
  }

  Future<void> _applyBulkColor(int colorIndex) async {
    final targets = _selectedNotesList();
    if (targets.isEmpty) return;
    Navigator.of(context).pop();
    Haptics.tap();
    await _repository.updateAll(
      targets.map((n) => n.copyWith(colorIndex: colorIndex)).toList(),
    );
    if (!mounted) return;
    _clearSelection();
    await _load();
  }

  Future<void> _showBulkColorPicker() async {
    final count = context.read<HomeCubit>().state.selectedIds.length;
    Haptics.tap();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.colorSheetTitle(count),
                  style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    for (var i = 0; i < AppConstants.noteColors.length; i++)
                      ColorDotWidget(
                        color: AppConstants.noteColors[i],
                        onTap: () => _applyBulkColor(i),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNoteTitle),
        content: Text(l10n.deleteNoteTrashMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _deleteNote(Note note) {
    Haptics.heavy();
    unawaited(_trashNotes(<Note>[note]));
  }

  /// Called from Dismissible.onDismissed (delete direction).
  /// Removes the note from cubit state synchronously BEFORE the async
  /// DB write, ensuring the Dismissible is never orphaned in the tree.
  void _trashNoteSwipe(Note note) {
    Haptics.heavy();
    context.read<HomeCubit>().removeNote(note.id);
    unawaited(_trashNotes(<Note>[note]));
  }

  /// Called from Dismissible.onDismissed (pin direction).
  /// Toggles pin in cubit state synchronously, then persists to DB async.
  void _pinNoteSwipe(Note note) {
    Haptics.tap();
    context.read<HomeCubit>().togglePinOptimistic(note.id);
    unawaited(_persistPin(note));
  }

  Future<void> _persistPin(Note note) async {
    await _repository.update(note.copyWith(pinned: !note.pinned));
  }

  Future<void> _trashNotes(List<Note> notes) async {
    // Idempotent optimistic removal: safe to call even if the caller already
    // removed the note (e.g. from Dismissible.onDismissed via _trashNoteSwipe).
    final cubit = context.read<HomeCubit>();
    for (final note in notes) {
      cubit.removeNote(note.id);
    }

    await _repository.softDeleteAll(notes.map((n) => n.id).toList());
    await ReminderService.cancelAll(notes.map((n) => n.id));
    if (!mounted || notes.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    GlobalSnackBar.show(
      message: notes.length == 1
          ? l10n.movedToTrashOne
          : l10n.movedToTrashCount(notes.length),
      actionLabel: l10n.undoAction,
      duration: const Duration(seconds: 5),
      onAction: () async {
        await _repository.restoreAll(notes.map((n) => n.id).toList());
        for (final note in notes) {
          cubit.restoreNote(note);
          unawaited(ReminderService.sync(note));
        }
      },
    );
  }

  Future<bool?> _confirmBulkDelete(int count) {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteManyTitle),
        content: Text(l10n.deleteManyMessage(count)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.scheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final targets = _selectedNotesList();
    if (targets.isEmpty) return;
    final confirmed = await _confirmBulkDelete(targets.length);
    if (confirmed != true || !mounted) return;

    Haptics.heavy();
    _clearSelection();
    await _trashNotes(targets);
  }

  Widget _swipeable(ColorScheme scheme, Note note) {
    return Dismissible(
      key: Key(note.id.toString()),
      direction: context.read<HomeCubit>().state.selectionMode
          ? DismissDirection.none
          : DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) return _confirmDelete();
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _trashNoteSwipe(note);
        } else {
          _pinNoteSwipe(note);
        }
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsetsDirectional.only(start: 24.w),
        decoration: BoxDecoration(
          color: note.pinned
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: note.pinned
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsetsDirectional.only(end: 24.w),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
      ),
      child: Hero(
        tag: 'note-bg-${note.id}',
        child: NoteCard(
          note: note,
          selectionMode: context.read<HomeCubit>().state.selectionMode,
          isSelected: context.read<HomeCubit>().state.selectedIds.contains(
            note.id,
          ),
          onLongPress: () => _enterSelection(note),
          onTap: () => context.read<HomeCubit>().state.selectionMode
              ? _toggleSelection(note)
              : _openViewer(note),
          onEdit: () => _openEditor(note),
          onDelete: () => _deleteNote(note),
          onPin: () => _togglePin(note),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      // Search typing only touches query/searchResults/searchHistory, which
      // are consumed by their own scoped BlocBuilders below — the page shell
      // (header, filters, grid, FAB) must not rebuild on every keystroke.
      buildWhen: (prev, cur) =>
          prev.notes != cur.notes ||
          prev.viewState != cur.viewState ||
          prev.selectedIds != cur.selectedIds ||
          prev.gridLayout != cur.gridLayout ||
          prev.activeTag != cur.activeTag ||
          prev.activeFolder != cur.activeFolder ||
          prev.folders != cur.folders ||
          prev.customOrder != cur.customOrder ||
          prev.sortMode != cur.sortMode ||
          prev.isSearching != cur.isSearching,
      builder: (context, state) {
        final scheme = context.scheme;
        final notes = state.sortedNotes;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -.15),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: state.selectionMode
                      ? SelectionHeaderWidget(
                          key: const ValueKey('selection-header'),
                          count: state.selectedIds.length,
                          totalCount: notes.length,
                          onSelectAll: _selectAll,
                          onClose: _clearSelection,
                        )
                      : HeaderWidget(
                          key: const ValueKey('default-header'),
                          notesCount: notes.length,
                          sort: _sortModeToNoteSort(state.sortMode),
                          isGrid: state.gridLayout,
                          onToggleLayout: _toggleLayout,
                          onSortChanged: (sort) => context
                              .read<HomeCubit>()
                              .setSort(_noteSortToSortMode(sort)),
                          onOpenSettings: _openSettings,
                          onOpenVault: _openVault,
                          onOpenTrash: _openTrash,
                        ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchSubmitted,
                    textInputAction: TextInputAction.search,
                    onTapOutside: (_) => _searchFocusNode.unfocus(),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).homeSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _SearchClearButton(
                        onPressed: _clearSearchWidget,
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                    ),
                  ),
                ),
                _SearchHistoryPanels(
                  focused: _searchFocused,
                  onSelected: _applySearchTerm,
                  onRemove: (term) =>
                      context.read<HomeCubit>().removeSearchHistory(term),
                  onClear: () => context.read<HomeCubit>().clearSearchHistory(),
                ),
                Expanded(
                  child: state.isSearching
                      ? _SearchResultsArea(onTap: _openSearchResult)
                      : state.viewState == ViewState.loading &&
                            state.notes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : notes.isEmpty
                      ? EmptyState(isSearching: state.query.trim().isNotEmpty)
                      : Column(
                          children: <Widget>[
                            TagFilterRow(
                              tags: state.allTags,
                              activeTag: state.activeTag,
                              onSelected: (tag) =>
                                  context.read<HomeCubit>().setActiveTag(tag),
                            ),
                            FolderFilterRow(
                              folders: state.folders,
                              activeFolder: state.activeFolder,
                              onSelected: (folder) => context
                                  .read<HomeCubit>()
                                  .setActiveFolder(folder),
                            ),
                            SizedBox(height: 8.h),
                            Expanded(
                              child: notes.isEmpty && state.activeTag != null
                                  ? Center(
                                      child: Text(
                                        AppLocalizations.of(
                                          context,
                                        ).noNotesWithTag,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                      ),
                                    )
                                  : state.gridLayout
                                  ? _buildGrid(scheme, notes)
                                  : _buildList(scheme, notes),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: state.selectionMode
              ? null
              : Semantics(
                  button: true,
                  label: AppLocalizations.of(context).semNewNote,
                  hint: AppLocalizations.of(context).semNewNoteHint,
                  child: FloatingActionButton.extended(
                    onPressed: () => _openEditor(),
                    elevation: 6,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(AppLocalizations.of(context).homeNewNote),
                  ),
                ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .3),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: !state.selectionMode
                ? const SizedBox.shrink(key: ValueKey('no-bar'))
                : SelectionBarWidget(
                    key: const ValueKey('selection-bar'),
                    count: state.selectedIds.length,
                    anyUnpinned: _selectedNotesList().any((n) => !n.pinned),
                    onColor: _showBulkColorPicker,
                    onPin: _bulkTogglePin,
                    onDelete: _deleteSelected,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(ColorScheme scheme, List<Note> notes) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.w,
        mainAxisExtent: 148.h,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: notes.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) =>
          RepaintBoundary(child: _swipeable(scheme, notes[index])),
    );
  }

  Widget _buildList(ColorScheme scheme, List<Note> notes) {
    final isCustom =
        context.read<HomeCubit>().state.sortMode == SortMode.custom;
    if (isCustom) {
      return ReorderableListView.builder(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
        itemCount: notes.length,
        onReorder: (oldIndex, newIndex) {
          context.read<HomeCubit>().reorder(oldIndex, newIndex);
        },
        itemBuilder: (context, index) => Padding(
          key: ValueKey(notes[index].id),
          padding: EdgeInsets.only(bottom: 10.h),
          child: SizedBox(
            height: 128.h,
            child: RepaintBoundary(child: _swipeable(scheme, notes[index])),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
      itemCount: notes.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: SizedBox(
          height: 128.h,
          child: RepaintBoundary(child: _swipeable(scheme, notes[index])),
        ),
      ),
    );
  }
}

/// The suffix "clear search" button. Watches only the [HomeState.query] field
/// so the page shell (and the results list) are not rebuilt on query changes.
class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, cur) => prev.query != cur.query,
      builder: (context, state) {
        if (state.query.isEmpty) return const SizedBox.shrink();
        return IconButton(
          tooltip: AppLocalizations.of(context).homeClearSearch,
          icon: const Icon(Icons.close_rounded),
          onPressed: onPressed,
        );
      },
    );
  }
}

/// The search-history panel. Visibility depends on the search field focus
/// ([ValueNotifier]) and the panel content on [HomeState.searchHistory], so
/// both are subscribed to in isolation — a focus change or a recorded term
/// never touches the rest of the page.
class _SearchHistoryPanels extends StatelessWidget {
  const _SearchHistoryPanels({
    required this.focused,
    required this.onSelected,
    required this.onRemove,
    required this.onClear,
  });

  final ValueListenable<bool> focused;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: focused,
      builder: (context, isFocused, _) {
        return BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (prev, cur) =>
              prev.searchHistory != cur.searchHistory ||
              prev.query != cur.query,
          builder: (context, state) {
            if (!isFocused ||
                state.query.trim().isNotEmpty ||
                state.searchHistory.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 10.h),
              child: SearchHistoryPanel(
                history: state.searchHistory,
                onSelected: onSelected,
                onRemove: onRemove,
                onClear: onClear,
              ),
            );
          },
        );
      },
    );
  }
}

/// The advanced-search results. Rebuilds only when the query or its results
/// change, keeping header/filters/grid untouched while typing.
class _SearchResultsArea extends StatelessWidget {
  const _SearchResultsArea({required this.onTap});

  final ValueChanged<NoteSearchMatch> onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, cur) =>
          prev.query != cur.query ||
          prev.searchResults != cur.searchResults ||
          prev.viewState != cur.viewState,
      builder: (context, state) {
        if (state.viewState == ViewState.loading &&
            state.searchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.searchResults.isEmpty) {
          return EmptyState(isSearching: true);
        }
        return SearchResultsList(
          results: state.searchResults,
          query: state.query.trim(),
          onTap: onTap,
        );
      },
    );
  }
}
