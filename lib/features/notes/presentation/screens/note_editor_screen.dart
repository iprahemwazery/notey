import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import 'package:notey/core/services/file_opener_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';
import 'package:notey/features/notes/data/repositories_impl/note_history_repository.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/entities/note_history.dart';

import 'package:notey/features/notes/domain/usecases/create_note.dart';
import 'package:notey/features/notes/domain/usecases/log_note_history.dart';
import 'package:notey/features/notes/domain/usecases/soft_delete_note_by_id.dart';
import 'package:notey/features/notes/domain/usecases/trim_note_history.dart';
import 'package:notey/features/notes/domain/usecases/update_note.dart';
import 'package:notey/features/notes/presentation/cubits/editor_cubit.dart';

import 'package:notey/features/notes/presentation/cubits/editor_state.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'drawing_screen.dart';
import 'voice_recorder_sheet.dart';

import '../widgets/editor/attachment_source_sheet.dart';
import '../widgets/editor/attachment_strip_widget.dart';
import '../widgets/editor/editor_attachment_header.dart';
import '../widgets/editor/editor_color_picker_widget.dart';
import '../widgets/editor/editor_text_fields.dart';
import '../widgets/editor/folder_picker_widget.dart';
import '../widgets/editor/format_toolbar_widget.dart';
import '../widgets/editor/gradient_save_button_widget.dart';
import '../widgets/editor/protection_menu_widget.dart';
import '../widgets/editor/reminder_row_widget.dart';
import '../widgets/editor/tags_editor_widget.dart';
import '../widgets/editor/undo_redo_button_widget.dart';

import 'package:notey/core/widgets/note_snackbar.dart';

import 'package:notey/widgets/common/app_dialogs.dart';

enum _DiscardAction { save, discard, cancel }

/// Create/edit screen. Auto-stamps created & updated timestamps on save.
class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({
    super.key,
    this.note,
    this.repository,
    this.unlockPassword,
  });

  /// When null the screen is in "create" mode.
  final Note? note;
  final NoteRepository? repository;

  /// Password used to decrypt [note]; required to re-encrypt on save
  /// when the note is protected.
  final String? unlockPassword;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final NoteRepository _repository = widget.repository ?? NoteRepositoryImpl();
  late final NoteHistoryRepository _historyRepo = NoteHistoryRepositoryImpl();
  late final ImageStore _imageStore = ImageStore();

  late final EditorCubit _cubit;

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  final TextEditingController _tagController = TextEditingController();

  /// Password chosen this session for an unprotected note (applied on save).
  String? _pendingLockPassword;

  /// Set when the user removes protection from an unlocked protected note.
  bool _removeProtection = false;

  /// Tracks whether anything was persisted this session (a lock, a save). Used
  /// so the caller (home) reloads and reflects the change even when the user
  /// leaves via back instead of pressing Save.
  bool _changed = false;

  /// Plaintext baseline for change detection. NoteLockService encrypts only
  /// title & content, so these must be compared against the decrypted draft
  /// rather than the ciphertext in the editor's note.
  String _baseTitle = '';
  String _baseContent = '';
  int _baseColorIndex = 0;
  List<String> _baseTags = const <String>[];
  List<String> _baseAttachments = const <String>[];
  DateTime? _baseReminderAt;

  /// Attachments picked in this session that no saved note references yet.
  final List<String> _newAttachments = <String>[];

  /// Set to true once the screen is allowed to be popped (after save/delete/discard).
  bool _allowPop = false;

  /// Guards against double-save taps while a write is in flight.
  bool _saving = false;

  /// Debounce timer for undo snapshots — fires 600ms after the last keystroke.
  Timer? _snapshotTimer;

  /// Whether the note will be stored encrypted when saved.
  bool get _willBeProtected {
    if (widget.note?.isLocked ?? false) return !_removeProtection;
    return _pendingLockPassword != null;
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _cubit = EditorCubit(
      repository: _repository,
      historyRepo: _historyRepo,
      existingNote: widget.note,
    );

    _titleController = TextEditingController(text: _cubit.state.title);
    _contentController = TextEditingController(text: _cubit.state.content);

    _titleController.addListener(_onTitleChanged);
    _contentController.addListener(_onContentChanged);
    _updateBaselines(_cubit.state);
  }

  /// Captures the current plaintext state as the "saved" baseline used for
  /// change detection (see [_baseTitle]).
  void _updateBaselines(EditorState state) {
    _baseTitle = state.title;
    _baseContent = state.content;
    _baseColorIndex = state.colorIndex;
    _baseTags = List<String>.of(state.tags);
    _baseAttachments = List<String>.of(state.attachments);
    _baseReminderAt = state.reminderAt;
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _titleController.removeListener(_onTitleChanged);
    _contentController.removeListener(_onContentChanged);
    _cubit.close();
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  void _onTitleChanged() => _cubit.updateTitle(_titleController.text);

  void _onContentChanged() {
    _cubit.updateContent(_contentController.text);
    _scheduleSnapshot();
  }

  /// Pushes an undo snapshot 600 ms after the user stops typing.
  void _scheduleSnapshot() {
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && !_saving) _cubit.pushSnapshot();
    });
  }

  bool _computeHasChanges(EditorState state) {
    if (state.isEditing) {
      final DateTime? originalReminder = _baseReminderAt;
      final bool reminderChanged =
          (originalReminder?.millisecondsSinceEpoch ?? 0) !=
          (state.reminderAt?.millisecondsSinceEpoch ?? 0);
      return state.title != _baseTitle ||
          state.content != _baseContent ||
          _baseColorIndex != state.colorIndex ||
          !_listEquals(_baseTags, state.tags) ||
          !_listEquals(_baseAttachments, state.attachments) ||
          reminderChanged;
    }
    return state.title.trim().isNotEmpty ||
        state.content.trim().isNotEmpty ||
        state.tags.isNotEmpty ||
        state.attachments.isNotEmpty ||
        state.reminderAt != null;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _addTag(String raw) {
    final tag = raw.trim().replaceAll(RegExp(r'#'), '');
    if (tag.isEmpty || _cubit.state.tags.contains(tag)) {
      _tagController.clear();
      return;
    }
    _cubit.addTag(tag);
    _tagController.clear();
  }

  Future<void> _drawFromCanvas() async {
    await Haptics.tap();
    if (!mounted) return;
    final drawPath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const DrawingScreen(),
      ),
    );
    if (drawPath == null || !mounted) return;
    await _attachPicked(XFile(drawPath), isDocument: false);
  }

  Future<void> _addAttachment() async {
    await Haptics.tap();
    if (!mounted) return;
    final source = await showAttachmentSourceSheet(context);
    if (source == null) return;

    try {
      switch (source) {
        case AttachmentSource.camera:
          final picked = await _imageStore.pickFromCamera();
          if (picked == null) return;
          await _attachPicked(picked, isDocument: false);
        case AttachmentSource.gallery:
          final picked = await _imageStore.pickFromGallery();
          if (picked == null) return;
          await _attachPicked(picked, isDocument: false);
        case AttachmentSource.file:
          final files = await FilePicker.pickFiles(type: FileType.any);
          for (final file in files) {
            final path = file.path;
            if (path == null) continue;
            await _attachPicked(XFile(path), isDocument: true);
          }
        case AttachmentSource.voice:
          if (!mounted) return;
          final voicePath = await showVoiceRecorderSheet(context);
          if (voicePath == null || !mounted) return;
          await _attachPicked(XFile(voicePath), isDocument: true);
        case AttachmentSource.draw:
          await _drawFromCanvas();
      }
    } on Exception {
      if (!mounted) return;
      GlassSnackbar.show(
        message: AppLocalizations.of(context).attachmentPickFailed,
        isError: true,
      );
    }
  }

  /// Copies the picked file into the app's private storage and shows it
  /// in the editor. Documents keep their original extension.
  Future<void> _attachPicked(XFile file, {required bool isDocument}) async {
    final path = isDocument
        ? await _imageStore.persistDocument(file)
        : await _imageStore.persist(file);
    if (!mounted) return;
    _cubit.addAttachment(path);
    _newAttachments.add(path);
  }

  Future<void> _removeAttachment(String path) async {
    await Haptics.tap();
    _cubit.removeAttachment(path);
    if (_newAttachments.contains(path)) {
      _newAttachments.remove(path);
      await _imageStore.delete(path);
    }
  }

  /// Opens a non-image attachment with the device's native viewer.
  Future<void> _openAttachment(String path) async {
    await Haptics.tap();
    final ok = await FileOpenerService.open(path);
    if (!ok && mounted) {
      GlassSnackbar.show(
        message: AppLocalizations.of(context).noAppToOpenFile,
        isError: true,
      );
    }
  }

  /// Dismisses the keyboard when tapping anywhere outside the focused field.
  void _unfocusEditor() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context);
    unawaited(Haptics.tap());
    final DateTime now = DateTime.now();
    final state = _cubit.state;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: state.reminderAt ?? now.add(const Duration(hours: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final TimeOfDay initial = TimeOfDay.fromDateTime(
      state.reminderAt ?? now.add(const Duration(hours: 1)),
    );
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (!mounted) return;
    if (time == null) return;
    final DateTime combined = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (!combined.isAfter(DateTime.now())) {
      GlassSnackbar.show(message: l10n.pastReminderToast, isError: true);
      return;
    }
    _cubit.setReminder(combined);
  }

  Future<void> _clearReminder() async {
    await Haptics.tap();
    _cubit.setReminder(null);
  }

  void _showReminderResult(ScheduleResult result) {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case ScheduleResult.success:
        GlassSnackbar.show(message: l10n.reminderScheduled);
      case ScheduleResult.permissionDenied:
        GlassSnackbar.show(
          message: l10n.reminderPermissionNeeded,
          actionLabel: l10n.settingsTitle,
          duration: const Duration(seconds: 4),
          onAction: () => ReminderService.openSystemSettings(),
        );
      case ScheduleResult.failed:
        GlassSnackbar.show(message: l10n.reminderFailed, isError: true);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final state = _cubit.state;
    final title = state.title.trim();
    if (title.isEmpty) {
      GlassSnackbar.show(
        message: AppLocalizations.of(context).titleRequired,
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final original = state.note;
      if (original != null &&
          original.isLocked &&
          widget.unlockPassword == null &&
          _pendingLockPassword == null) {
        // Never overwrite ciphertext with plaintext — re-locking is impossible
        // without the password, so refuse the save instead of corrupting it.
        if (!mounted) return;
        setState(() => _saving = false);
        GlassSnackbar.show(
          message: AppLocalizations.of(context).relockBeforeEditHint,
          isError: true,
        );
        return;
      }
      final now = DateTime.now();
      if (state.isEditing && original != null) {
        // Log previous state before updating
        if (!_removeProtection && widget.unlockPassword == null) {
          unawaited(_logHistory(original, title, state.content));
        }
        var updated = original.copyWith(
          title: title,
          content: state.content,
          attachments: state.attachments,
          colorIndex: state.colorIndex,
          tags: List<String>.of(state.tags),
          reminderAt: state.reminderAt,
          updatedAt: now,
        );
        if (original.isLocked) {
          if (_removeProtection) {
            // In-memory copy is decrypted; just drop the lock flags.
            updated = await NoteLockService.removeLock(updated);
          } else if (widget.unlockPassword != null) {
            updated = await NoteLockService.lock(
              updated,
              widget.unlockPassword!,
            );
          } else if (_pendingLockPassword != null) {
            updated = await NoteLockService.lock(
              updated,
              _pendingLockPassword!,
            );
          }
        } else if (_pendingLockPassword != null) {
          updated = await NoteLockService.lock(updated, _pendingLockPassword!);
        }
        await UpdateNote(_repository)(updated);
        if (state.reminderAt != null) {
          final result = await ReminderService.sync(updated);
          if (mounted) _showReminderResult(result);
        } else {
          unawaited(ReminderService.sync(updated));
        }
      } else {
        var created = Note.create(
          title: title,
          content: state.content,
          attachments: state.attachments,
          colorIndex: state.colorIndex,
          tags: List<String>.of(state.tags),
          reminderAt: state.reminderAt,
        );
        if (_pendingLockPassword != null) {
          created = await NoteLockService.lock(created, _pendingLockPassword!);
        }
        await CreateNote(_repository)(created);
        if (state.reminderAt != null) {
          final result = await ReminderService.sync(created);
          if (mounted) _showReminderResult(result);
        } else {
          unawaited(ReminderService.sync(created));
        }
      }

      _updateBaselines(state);
      _changed = true;
      await Haptics.light();
      if (!mounted) return;
      GlassSnackbar.show(message: AppLocalizations.of(context).noteSaved);
      _exitWith(result: true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      GlassSnackbar.show(
        message: AppLocalizations.of(context).noteSaveFailed,
        isError: true,
      );
    }
  }

  Future<void> _logHistory(
    Note note,
    String newTitle,
    String newContent,
  ) async {
    // Only log if content or title actually changed
    if (note.title == newTitle && note.content == newContent) return;
    try {
      final entry = NoteHistory.create(
        noteId: note.id,
        title: note.title,
        content: note.content,
      );
      await LogNoteHistory(_historyRepo)(entry);
      await TrimNoteHistory(_historyRepo)(note.id, keep: 30);
    } on Exception {
      // Non-critical: don't block the save
    }
  }

  /// Pops the screen on the next frame so PopScope sees the updated [canPop].
  void _exitWith({required bool result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result || _changed);
    });
  }

  Future<void> _handleBack() async {
    final state = _cubit.state;
    if (!_computeHasChanges(state)) {
      await _cleanupNewImages();
      if (mounted) {
        _exitWith(result: false);
      }
      return;
    }

    final action = await showDialog<_DiscardAction>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.unsavedChangesTitle),
          content: Text(l10n.unsavedChangesMessage),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, _DiscardAction.cancel),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _DiscardAction.discard),
              child: Text(l10n.discard),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, _DiscardAction.save),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );

    switch (action) {
      case _DiscardAction.save:
        await _save();
      case _DiscardAction.discard:
        await _cleanupNewImages();
        if (mounted) {
          _allowPop = true;
          Navigator.of(context).pop(_changed);
        }
      case _DiscardAction.cancel:
        break;
      case null:
        break;
    }
  }

  Future<void> _cleanupNewImages() async {
    for (final path in _newAttachments) {
      await _imageStore.delete(path);
    }
  }

  Future<void> _onProtectionAction(String action) async {
    switch (action) {
      case 'set':
        final password = await showPasswordDialog(
          context,
          title: AppLocalizations.of(context).secureDialogTitle,
          message: AppLocalizations.of(context).secureDialogMessage,
          confirmButtonLabel: AppLocalizations.of(context).secureConfirm,
          confirmRequired: true,
        );
        if (password == null || !mounted) return;
        setState(() {
          _pendingLockPassword = password;
          _removeProtection = false;
        });
        // Lock + persist immediately so the note is secured from the very
        // first press of "تأمين" — no need to also press Save.
        await _lockNow(password);
      case 'remove':
        Haptics.tap();
        setState(() {
          _pendingLockPassword = null;
          _removeProtection = true;
        });
        if (mounted) {
          GlassSnackbar.show(message: l10n.willSaveUnprotected);
        }
      case 'keep':
        Haptics.tap();
        setState(() => _removeProtection = false);
    }
  }

  /// Locks the current draft with [password] immediately: encrypts it, persists
  /// it, and adopts it as an existing note. Called on the first press of
  /// "تأمين" so the lock takes effect right away without an extra Save. Unlike
  /// [_save] it keeps the editor open for further edits and reports [_changed].
  Future<void> _lockNow(String password) async {
    if (_saving) return;
    final state = _cubit.state;
    final title = state.title.trim();
    final now = DateTime.now();
    setState(() => _saving = true);
    try {
      final original = state.note;
      if (state.isEditing && original != null) {
        var updated = original.copyWith(
          title: title,
          content: state.content,
          attachments: state.attachments,
          colorIndex: state.colorIndex,
          tags: List<String>.of(state.tags),
          reminderAt: state.reminderAt,
          updatedAt: now,
        );
        updated = await NoteLockService.lock(updated, password);
        await UpdateNote(_repository)(updated);
        if (state.reminderAt != null) {
          final result = await ReminderService.sync(updated);
          if (mounted) _showReminderResult(result);
        } else {
          unawaited(ReminderService.sync(updated));
        }
      } else {
        var created = Note.create(
          title: title,
          content: state.content,
          attachments: state.attachments,
          colorIndex: state.colorIndex,
          tags: List<String>.of(state.tags),
          reminderAt: state.reminderAt,
        );
        created = await NoteLockService.lock(created, password);
        await CreateNote(_repository)(created);
        // New note is now saved; adopt it so later saves update (not insert).
        _cubit.adoptNote(created);
        if (state.reminderAt != null) {
          final result = await ReminderService.sync(created);
          if (mounted) _showReminderResult(result);
        } else {
          unawaited(ReminderService.sync(created));
        }
      }

      _updateBaselines(state);
      _changed = true;
      await Haptics.light();
      if (mounted) {
        GlassSnackbar.show(message: l10n.securedToast);
      }
    } on Exception {
      if (!mounted) return;
      GlassSnackbar.show(
        message: AppLocalizations.of(context).noteSaveFailed,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppDialogs.confirm(
      context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteTrashMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    await Haptics.heavy();
    final id = _cubit.state.note?.id ?? widget.note?.id;
    if (id == null) return;
    await SoftDeleteNoteById(_repository)(id);
    if (!mounted) return;
    GlassSnackbar.show(message: l10n.movedToTrashOne);
    _exitWith(result: true);
  }

  void _applyUndoRedoToControllers() {
    _titleController.text = _cubit.state.title;
    _titleController.selection = TextSelection.collapsed(
      offset: _cubit.state.title.length,
    );
    _contentController.text = _cubit.state.content;
    _contentController.selection = TextSelection.collapsed(
      offset: _cubit.state.content.length,
    );
  }

  void _undo() {
    Haptics.tap();
    _snapshotTimer?.cancel();
    _cubit.undo();
    _applyUndoRedoToControllers();
  }

  void _redo() {
    Haptics.tap();
    _snapshotTimer?.cancel();
    _cubit.redo();
    _applyUndoRedoToControllers();
  }

  Future<void> _addAttachmentFromStrip() async {
    await _addAttachment();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EditorCubit, EditorState>(
        // The title/content fields are owned by their TextEditingControllers,
        // so per-keystroke updates to them must not rebuild the whole editor.
        buildWhen: (prev, next) =>
            prev.attachments != next.attachments ||
            prev.tags != next.tags ||
            prev.colorIndex != next.colorIndex ||
            prev.reminderAt != next.reminderAt ||
            prev.folder != next.folder ||
            prev.saving != next.saving ||
            prev.allowPop != next.allowPop ||
            prev.isEditing != next.isEditing ||
            prev.note != next.note ||
            prev.errorMessage != next.errorMessage ||
            prev.canUndo != next.canUndo ||
            prev.canRedo != next.canRedo,
        builder: (context, state) {
          return PopScope(
            canPop: _allowPop,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _handleBack();
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  state.isEditing
                      ? AppLocalizations.of(context).editorEditTitle
                      : AppLocalizations.of(context).editorNewTitle,
                ),
                actions: <Widget>[
                  IconButton(
                    tooltip: AppLocalizations.of(context).drawOption,
                    onPressed: _saving ? null : _drawFromCanvas,
                    icon: const Icon(Icons.draw_rounded),
                  ),
                  if (state.isEditing)
                    IconButton(
                      tooltip: AppLocalizations.of(context).delete,
                      onPressed: _saving ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ProtectionMenuWidget(
                    protected: _willBeProtected,
                    canRemove:
                        _willBeProtected &&
                        ((widget.note?.isLocked ?? false)
                            ? widget.unlockPassword != null
                            : true),
                    onSelect: _saving ? null : _onProtectionAction,
                  ),
                  Semantics(
                    button: true,
                    label: AppLocalizations.of(context).save,
                    child: TextButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(AppLocalizations.of(context).save),
                    ),
                  ),
                ],
              ),
              body: Column(
                children: <Widget>[
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          EditorColorPickerWidget(
                            selectedIndex: state.colorIndex,
                            onSelected: (index) {
                              Haptics.tap();
                              _cubit.setColor(index);
                            },
                          ),
                          SizedBox(height: 18.h),
                          EditorTitleField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            contentFocusNode: _contentFocus,
                            autofocus: !state.isEditing,
                            onTapOutside: _unfocusEditor,
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: <Widget>[
                              UndoRedoButtonWidget(
                                icon: Icons.undo_rounded,
                                tooltip: AppLocalizations.of(
                                  context,
                                ).undoAction,
                                enabled: state.canUndo,
                                onPressed: _undo,
                              ),
                              UndoRedoButtonWidget(
                                icon: Icons.redo_rounded,
                                tooltip: AppLocalizations.of(
                                  context,
                                ).redoAction,
                                enabled: state.canRedo,
                                onPressed: _redo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FormatToolbarWidget(
                                  controller: _contentController,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          EditorContentField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            onTapOutside: _unfocusEditor,
                          ),
                          SizedBox(height: 24.h),
                          TagsEditorWidget(
                            tags: state.tags,
                            onAdd: _addTag,
                            onRemove: (tag) => _cubit.removeTag(tag),
                          ),
                          SizedBox(height: 16.h),
                          FolderPickerWidget(
                            folder: state.folder,
                            onChanged: (f) => _cubit.setFolder(f),
                          ),
                          SizedBox(height: 16.h),
                          ReminderRowWidget(
                            reminderAt: state.reminderAt,
                            onPick: _pickReminder,
                            onClear: _clearReminder,
                          ),
                          SizedBox(height: 24.h),
                          EditorAttachmentHeader(
                            count: state.attachments.length,
                            onAdd: _addAttachmentFromStrip,
                          ),
                          if (state.attachments.isNotEmpty) ...<Widget>[
                            SizedBox(height: 12.h),
                            AttachmentStripWidget(
                              attachments: state.attachments,
                              onRemove: _removeAttachment,
                              onAdd: _addAttachmentFromStrip,
                              onOpenFile: _openAttachment,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
                    child: GradientSaveButtonWidget(
                      onPressed: _saving ? null : _save,
                      saving: _saving,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
