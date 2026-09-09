import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/widgets/note_snackbar.dart';

import 'package:notey/core/services/haptics.dart';
import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/share_receiver.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';
import 'package:notey/features/notes/domain/usecases/bulk_soft_delete_notes.dart';
import 'package:notey/features/notes/domain/usecases/get_all_notes_including_deleted.dart';
import 'package:notey/features/notes/domain/usecases/get_note.dart';
import 'package:notey/features/notes/domain/usecases/restore_notes.dart';
import 'package:notey/features/notes/domain/usecases/update_note.dart';

import 'package:notey/data/services/image_store.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/features/vault/presentation/screens/vault_screen.dart';

import 'package:notey/widgets/common/app_dialogs.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/entities/note_search_result.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';

import 'package:notey/features/notes/presentation/cubits/home_state.dart';

import 'package:notey/features/notes/presentation/widgets/home/home_app_bar.dart';
import 'package:notey/features/notes/presentation/widgets/home/home_bottom_bar.dart';
import 'package:notey/features/notes/presentation/widgets/home/home_notes_body.dart';
import 'package:notey/features/notes/presentation/widgets/home/home_search_field.dart';
import 'package:notey/features/notes/presentation/widgets/home/home_search_history.dart';
import 'package:notey/features/notes/presentation/widgets/home/new_note_fab.dart';
import 'package:notey/features/notes/presentation/widgets/home/notes_grid.dart';
import 'package:notey/features/notes/presentation/widgets/home/bulk_color_sheet.dart';
import 'package:notey/features/notes/presentation/widgets/sort_menu_widget.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'package:notey/app.dart' show noteyNavigatorKey;
import 'package:notey/features/notes/presentation/screens/note_editor_screen.dart';

import 'package:notey/features/settings/presentation/screens/settings_screen.dart';

import 'package:notey/features/trash/presentation/screens/trash_screen.dart';

import 'package:notey/features/notes/presentation/screens/note_view_screen.dart';

/// Home screen: shows the notes grid + search + add/edit/pin/delete actions.
///
/// This is intentionally a thin shell: rendering lives in the extracted
/// `widgets/home/` widgets and repository logic in [HomeCubit], so this file
/// only wires state, navigation and dialogs together.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.repository,
    this.lockController,
    this.biometricService,
    this.imageStore,
    this.onOpenDestination,
  });

  final NoteRepository? repository;
  final AppLockController? lockController;
  final BiometricService? biometricService;

  /// Shared image store injected by the app shell so home + trash reuse the
  /// same backing files.
  final ImageStore? imageStore;

  /// When provided (e.g. inside the main tab shell), tapping Vault/Trash/
  /// Settings switches to the matching tab instead of pushing a new route.
  /// Indices follow the shell's tab order: 1=vault, 2=trash, 3=settings.
  final ValueChanged<int>? onOpenDestination;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final NoteRepository _repository = widget.repository ?? NoteRepositoryImpl();
  late final AppLockController? _lockController = widget.lockController;
  late final BiometricService? _biometricService = widget.biometricService;
  late final ImageStore _imageStore = widget.imageStore ?? ImageStore();
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
    final Note? note = await GetNote(_repository)(noteId);
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
      final all = await GetAllNotesIncludingDeleted(_repository)();
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
        GlassSnackbar.show(
          message: AppLocalizations.of(context).wrongPasswordToast,
          isError: true,
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
            note.isLocked != (await GetNote(_repository)(note.id))?.isLocked)) {
      _load();
    }
  }

  Future<void> _openSettings() async {
    final controller = _lockController;
    final biometrics = _biometricService;
    if (controller == null || biometrics == null) return;
    await Haptics.tap();
    if (!mounted) return;
    final destination = widget.onOpenDestination;
    if (destination != null) {
      destination(3);
      return;
    }
    await Get.to<void>(
      () => SettingsScreen(
        repository: _repository,
        lockController: controller,
        biometricService: biometrics,
      ),
    );
  }

  Future<void> _openVault() async {
    await Haptics.tap();
    if (!mounted) return;
    final destination = widget.onOpenDestination;
    if (destination != null) {
      destination(1);
      return;
    }
    await Get.to<void>(() => VaultScreen(repository: SecureVaultRepository()));
  }

  Future<void> _openTrash() async {
    await Haptics.tap();
    if (!mounted) return;
    final destination = widget.onOpenDestination;
    if (destination != null) {
      destination(2);
      return;
    }
    await Get.to<void>(
      () => TrashScreen(repository: _repository, imageStore: _imageStore),
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
    Haptics.tap();
    await context.read<HomeCubit>().bulkTogglePin();
  }

  void _applyBulkColor(int colorIndex) {
    Navigator.of(context).pop();
    Haptics.tap();
    context.read<HomeCubit>().applyBulkColor(colorIndex);
  }

  Future<void> _showBulkColorPicker() async {
    final count = context.read<HomeCubit>().state.selectedIds.length;
    Haptics.tap();
    await showBulkColorSheet(context, count: count, onColor: _applyBulkColor);
  }

  Future<bool> _confirmDelete() {
    final l10n = AppLocalizations.of(context);
    return AppDialogs.confirm(
      context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteTrashMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
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
    await UpdateNote(_repository)(note.copyWith(pinned: !note.pinned));
  }

  Future<void> _trashNotes(List<Note> notes) async {
    // Idempotent optimistic removal: safe to call even if the caller already
    // removed the note (e.g. from Dismissible.onDismissed via _trashNoteSwipe).
    final cubit = context.read<HomeCubit>();
    for (final note in notes) {
      cubit.removeNote(note.id);
    }

    await BulkSoftDeleteNotes(_repository)(notes.map((n) => n.id).toList());
    await ReminderService.cancelAll(notes.map((n) => n.id));
    if (!mounted || notes.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    GlassSnackbar.show(
      message: notes.length == 1
          ? l10n.movedToTrashOne
          : l10n.movedToTrashCount(notes.length),
      actionLabel: l10n.undoAction,
      duration: const Duration(seconds: 5),
      onAction: () async {
        await RestoreNotes(_repository)(notes.map((n) => n.id).toList());
        for (final note in notes) {
          cubit.restoreNote(note);
          unawaited(ReminderService.sync(note));
        }
      },
    );
  }

  Future<bool> _confirmBulkDelete(int count) {
    final l10n = AppLocalizations.of(context);
    return AppDialogs.confirm(
      context,
      title: l10n.deleteManyTitle,
      message: l10n.deleteManyMessage(count),
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
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

  Future<bool?> _confirmSwipe(DismissDirection direction, Note note) {
    if (direction == DismissDirection.startToEnd) {
      // Pin is not a destructive action: toggle it in place and snap the
      // card back instead of dismissing it. Dismissible must always be
      // removed from the tree after onDismissed, which a pin toggle can't
      // guarantee, so we never let the swipe complete here.
      _pinNoteSwipe(note);
      return Future.value(false);
    }
    return _confirmDelete();
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    await context.read<HomeCubit>().reorder(oldIndex, newIndex);
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
        final notes = state.sortedNotes;
        final selectionMode = state.selectionMode;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                HomeAppBar(
                  selectionMode: selectionMode,
                  count: state.selectedIds.length,
                  totalCount: notes.length,
                  notesCount: notes.length,
                  sort: _sortModeToNoteSort(state.sortMode),
                  isGrid: state.gridLayout,
                  onToggleLayout: _toggleLayout,
                  onSortChanged: (sort) => context.read<HomeCubit>().setSort(
                    _noteSortToSortMode(sort),
                  ),
                  onOpenSettings: _openSettings,
                  onOpenVault: _openVault,
                  onOpenTrash: _openTrash,
                  onSelectAll: _selectAll,
                  onClose: _clearSelection,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                  child: HomeSearchField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: _onSearchChanged,
                    onSubmitted: _searchSubmitted,
                    onClear: _clearSearchWidget,
                  ),
                ),
                HomeSearchHistory(
                  focused: _searchFocused,
                  onSelected: _applySearchTerm,
                  onRemove: (term) =>
                      context.read<HomeCubit>().removeSearchHistory(term),
                  onClear: () => context.read<HomeCubit>().clearSearchHistory(),
                ),
                HomeNotesBody(
                  isSearching: state.isSearching,
                  viewState: state.viewState,
                  notes: notes,
                  query: state.query,
                  onOpenSearchResult: _openSearchResult,
                  onGridEntries: (ctx, list) => NotesGrid(
                    notes: list,
                    gridLayout: true,
                    isCustomOrder: false,
                    onTap: (n) =>
                        selectionMode ? _toggleSelection(n) : _openViewer(n),
                    onLongPress: _enterSelection,
                    onEdit: _openEditor,
                    onDelete: _deleteNote,
                    onPin: _togglePin,
                    onConfirmSwipe: _confirmSwipe,
                    onSwipedStartToEnd: _pinNoteSwipe,
                    onSwipedEndToStart: _trashNoteSwipe,
                    onReorder: _reorder,
                  ),
                  onListEntries: (ctx, list) => NotesGrid(
                    notes: list,
                    gridLayout: false,
                    isCustomOrder:
                        context.read<HomeCubit>().state.sortMode ==
                        SortMode.custom,
                    onTap: (n) =>
                        selectionMode ? _toggleSelection(n) : _openViewer(n),
                    onLongPress: _enterSelection,
                    onEdit: _openEditor,
                    onDelete: _deleteNote,
                    onPin: _togglePin,
                    onConfirmSwipe: _confirmSwipe,
                    onSwipedStartToEnd: _pinNoteSwipe,
                    onSwipedEndToStart: _trashNoteSwipe,
                    onReorder: _reorder,
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: selectionMode
              ? null
              : NewNoteFab(onPressed: () => _openEditor()),
          bottomNavigationBar: HomeBottomBar(
            selectionMode: selectionMode,
            count: state.selectedIds.length,
            anyUnpinned: _selectedNotesList().any((n) => !n.pinned),
            onColor: _showBulkColorPicker,
            onPin: _bulkTogglePin,
            onDelete: _deleteSelected,
          ),
        );
      },
    );
  }
}
