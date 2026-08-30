import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import 'dart:async';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/file_opener_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/utils/arabic_date_time.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/core/utils/attachment_utils.dart';

import 'package:notey/core/utils/file_icons.dart';

import 'package:notey/core/utils/color_utils.dart';

import 'package:notey/data/repositories/note_history_repository.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';

import 'package:notey/features/notes/model/note_history.dart';

import 'package:notey/features/notes/cubit/editor_cubit.dart';

import 'package:notey/features/notes/cubit/editor_state.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'drawing_screen.dart';
import 'voice_recorder_sheet.dart';

enum _ImageSource { camera, gallery, file, voice, draw }

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
  late final NoteRepository _repository = widget.repository ?? NoteRepository();
  late final NoteHistoryRepository _historyRepo = NoteHistoryRepository();
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
      final note = state.note;
      if (note == null) return false;
      final DateTime? originalReminder = note.reminderAt;
      final bool reminderChanged =
          (originalReminder?.millisecondsSinceEpoch ?? 0) !=
          (state.reminderAt?.millisecondsSinceEpoch ?? 0);
      return state.title != note.title ||
          state.content != note.content ||
          state.colorIndex != note.colorIndex ||
          !_listEquals(state.tags, note.tags) ||
          !_listEquals(state.attachments, note.attachments) ||
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
    final source = await showModalBottomSheet<_ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  l10n.addImageSheetTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 16.h),
                _SheetOption(
                  icon: Icons.photo_camera_rounded,
                  label: l10n.cameraOption,
                  onTap: () => Navigator.pop(context, _ImageSource.camera),
                ),
                SizedBox(height: 8.h),
                _SheetOption(
                  icon: Icons.photo_library_rounded,
                  label: l10n.galleryOption,
                  onTap: () => Navigator.pop(context, _ImageSource.gallery),
                ),
                SizedBox(height: 8.h),
                _SheetOption(
                  icon: Icons.attach_file_rounded,
                  label: l10n.fileFromDeviceOption,
                  onTap: () => Navigator.pop(context, _ImageSource.file),
                ),
                SizedBox(height: 8.h),
                _SheetOption(
                  icon: Icons.mic_rounded,
                  label: l10n.voiceNoteOption,
                  onTap: () => Navigator.pop(context, _ImageSource.voice),
                ),
                SizedBox(height: 8.h),
                _SheetOption(
                  icon: Icons.draw_rounded,
                  label: l10n.drawOption,
                  onTap: () => Navigator.pop(context, _ImageSource.draw),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    try {
      switch (source) {
        case _ImageSource.camera:
          final picked = await _imageStore.pickFromCamera();
          if (picked == null) return;
          await _attachPicked(picked, isDocument: false);
        case _ImageSource.gallery:
          final picked = await _imageStore.pickFromGallery();
          if (picked == null) return;
          await _attachPicked(picked, isDocument: false);
        case _ImageSource.file:
          final files = await FilePicker.pickFiles(type: FileType.any);
          for (final file in files) {
            final path = file.path;
            if (path == null) continue;
            await _attachPicked(XFile(path), isDocument: true);
          }
        case _ImageSource.voice:
          if (!mounted) return;
          final voicePath = await showVoiceRecorderSheet(context);
          if (voicePath == null || !mounted) return;
          await _attachPicked(XFile(voicePath), isDocument: true);
        case _ImageSource.draw:
          await _drawFromCanvas();
      }
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).attachmentPickFailed),
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noAppToOpenFile)),
      );
    }
  }

  /// Dismisses the keyboard when tapping anywhere outside the focused field.
  void _unfocusEditor() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.pastReminderToast)));
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
    final String msg;
    final SnackBarAction? action;
    switch (result) {
      case ScheduleResult.success:
        msg = l10n.reminderScheduled;
        action = null;
      case ScheduleResult.permissionDenied:
        msg = l10n.reminderPermissionNeeded;
        action = SnackBarAction(
          label: l10n.settingsTitle,
          onPressed: () => ReminderService.openSystemSettings(),
        );
      case ScheduleResult.failed:
        msg = l10n.reminderFailed;
        action = null;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
          duration: const Duration(seconds: 4),
          content: Text(msg),
          action: action,
        ),
      );
  }

  Future<void> _save() async {
    if (_saving) return;
    final state = _cubit.state;
    final title = state.title.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).titleRequired)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final original = widget.note;
      if (original != null &&
          original.isLocked &&
          widget.unlockPassword == null) {
        // Never overwrite ciphertext with plaintext — re-locking is impossible
        // without the password, so refuse the save instead of corrupting it.
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).relockBeforeEditHint),
          ),
        );
        return;
      }
      final now = DateTime.now();
      if (state.isEditing) {
        // Log previous state before updating
        if (!_removeProtection && widget.unlockPassword == null) {
          unawaited(_logHistory(original!, title, state.content));
        }
        var updated = original!.copyWith(
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
          }
        } else if (_pendingLockPassword != null) {
          updated = await NoteLockService.lock(updated, _pendingLockPassword!);
        }
        await _repository.update(updated);
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
        await _repository.insert(created);
        if (state.reminderAt != null) {
          final result = await ReminderService.sync(created);
          if (mounted) _showReminderResult(result);
        } else {
          unawaited(ReminderService.sync(created));
        }
      }

      await Haptics.light();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noteSaved)),
      );
      _exitWith(result: true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).noteSaveFailed)),
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
      await _historyRepo.log(entry);
      await _historyRepo.trim(note.id, keep: 30);
    } on Exception {
      // Non-critical: don't block the save
    }
  }

  /// Pops the screen on the next frame so PopScope sees the updated [canPop].
  void _exitWith({required bool result}) {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(result);
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
          Navigator.of(context).pop();
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
      case 'remove':
        Haptics.tap();
        setState(() {
          _pendingLockPassword = null;
          _removeProtection = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).willSaveUnprotected),
            ),
          );
        }
      case 'keep':
        Haptics.tap();
        setState(() => _removeProtection = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
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
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Haptics.heavy();
    await _repository.softDelete(widget.note!.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).movedToTrashOne)),
    );
    _exitWith(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                  _ProtectionMenu(
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
                          _ColorPicker(
                            selectedIndex: state.colorIndex,
                            onSelected: (index) {
                              Haptics.tap();
                              _cubit.setColor(index);
                            },
                          ),
                          SizedBox(height: 18.h),
                          TextField(
                            controller: _titleController,
                            focusNode: _titleFocus,
                            autofocus: !state.isEditing,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => _contentFocus.requestFocus(),
                            onTapOutside: (_) => _unfocusEditor(),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              ).editorTitleHint,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: <Widget>[
                              _UndoRedoButton(
                                icon: Icons.undo_rounded,
                                tooltip: AppLocalizations.of(
                                  context,
                                ).undoAction,
                                enabled: state.canUndo,
                                onPressed: () {
                                  Haptics.tap();
                                  _snapshotTimer?.cancel();
                                  _cubit.undo();
                                  _titleController.text = _cubit.state.title;
                                  _titleController.selection =
                                      TextSelection.collapsed(
                                        offset: _cubit.state.title.length,
                                      );
                                  _contentController.text =
                                      _cubit.state.content;
                                  _contentController.selection =
                                      TextSelection.collapsed(
                                        offset: _cubit.state.content.length,
                                      );
                                },
                              ),
                              _UndoRedoButton(
                                icon: Icons.redo_rounded,
                                tooltip: AppLocalizations.of(
                                  context,
                                ).redoAction,
                                enabled: state.canRedo,
                                onPressed: () {
                                  Haptics.tap();
                                  _snapshotTimer?.cancel();
                                  _cubit.redo();
                                  _titleController.text = _cubit.state.title;
                                  _titleController.selection =
                                      TextSelection.collapsed(
                                        offset: _cubit.state.title.length,
                                      );
                                  _contentController.text =
                                      _cubit.state.content;
                                  _contentController.selection =
                                      TextSelection.collapsed(
                                        offset: _cubit.state.content.length,
                                      );
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _FormatToolbar(
                                  controller: _contentController,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          TextField(
                            controller: _contentController,
                            focusNode: _contentFocus,
                            minLines: 8,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            onTapOutside: (_) => _unfocusEditor(),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(
                                context,
                              ).editorContentHint,
                              alignLabelWithHint: true,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          _TagsEditor(
                            tags: state.tags,
                            onAdd: _addTag,
                            onRemove: (tag) => _cubit.removeTag(tag),
                          ),
                          SizedBox(height: 16.h),
                          _FolderPicker(
                            folder: state.folder,
                            onChanged: (f) => _cubit.setFolder(f),
                          ),
                          SizedBox(height: 16.h),
                          _ReminderRow(
                            reminderAt: state.reminderAt,
                            onPick: _pickReminder,
                            onClear: _clearReminder,
                          ),
                          SizedBox(height: 24.h),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8.w,
                            runSpacing: 4.h,
                            children: <Widget>[
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    ).attachmentsSection,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (state.attachments.isNotEmpty) ...<Widget>[
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${state.attachments.length}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                              TextButton.icon(
                                onPressed: _addAttachment,
                                icon: const Icon(Icons.attach_file_rounded),
                                label: Text(
                                  AppLocalizations.of(context).addAttachment,
                                ),
                              ),
                            ],
                          ),
                          if (state.attachments.isNotEmpty) ...<Widget>[
                            SizedBox(height: 12.h),
                            _AttachmentStrip(
                              attachments: state.attachments,
                              onRemove: _removeAttachment,
                              onAdd: _addAttachment,
                              onOpenFile: _openAttachment,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 20.h),
                    child: _GradientSaveButton(
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

enum _DiscardAction { save, discard, cancel }

/// AppBar action toggling the note's password protection.
class _ProtectionMenu extends StatelessWidget {
  const _ProtectionMenu({
    required this.protected,
    required this.canRemove,
    required this.onSelect,
  });

  final bool protected;
  final bool canRemove;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).protectMenuTooltip,
      enabled: onSelect != null,
      onSelected: onSelect,
      icon: Icon(
        protected ? Icons.lock_rounded : Icons.lock_open_rounded,
        color: protected ? Theme.of(context).colorScheme.primary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context);
        return <PopupMenuEntry<String>>[
          if (!protected)
            PopupMenuItem<String>(
              value: 'set',
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(l10n.setPasswordItem),
                dense: true,
              ),
            )
          else ...<PopupMenuEntry<String>>[
            if (canRemove)
              PopupMenuItem<String>(
                value: 'remove',
                child: ListTile(
                  leading: Icon(
                    Icons.lock_open_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(l10n.removePasswordOnSave),
                  dense: true,
                ),
              )
            else
              PopupMenuItem<String>(
                value: 'keep',
                enabled: false,
                child: ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: Text(l10n.noteProtectedItem),
                  dense: true,
                ),
              ),
          ],
        ];
      },
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16.r),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: <Widget>[
                Icon(icon, color: scheme.primary),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Icon(
          Icons.palette_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: List<Widget>.generate(AppConstants.noteColors.length, (
              index,
            ) {
              final color = AppConstants.noteColors[index];
              final selected = index == selectedIndex;
              final onColor = ColorUtils.foregroundOn(color);
              return Semantics(
                button: true,
                label: l10n.semSelectColor(color.toARGB32().toRadixString(16)),
                child: GestureDetector(
                  onTap: () => onSelected(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: 34.w,
                    height: 34.h,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? onColor : Colors.transparent,
                        width: 2.5,
                      ),
                      boxShadow: selected
                          ? <BoxShadow>[
                              BoxShadow(
                                color: onColor.withValues(alpha: .35),
                                blurRadius: 8.r,
                              ),
                            ]
                          : null,
                    ),
                    child: selected
                        ? Icon(Icons.check_rounded, size: 18.w, color: onColor)
                        : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _AttachmentStrip extends StatelessWidget {
  const _AttachmentStrip({
    required this.attachments,
    required this.onRemove,
    required this.onAdd,
    required this.onOpenFile,
  });

  final List<String> attachments;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  /// Opens a non-image attachment with the device's native viewer.
  final ValueChanged<String> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = attachments.where(AttachmentUtils.isImage).toList();
    final files = attachments
        .where((a) => !AttachmentUtils.isImage(a))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (images.isNotEmpty)
          SizedBox(
            height: 96.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final path in images) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Image.file(
                            File(path),
                            width: 96.w,
                            height: 96.h,
                            fit: BoxFit.cover,
                            cacheWidth:
                                (96 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            errorBuilder: (_, _, _) => Container(
                              width: 96.w,
                              height: 96.h,
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Semantics(
                            button: true,
                            label: AppLocalizations.of(context).semRemoveImage,
                            child: GestureDetector(
                              onTap: () => onRemove(path),
                              child: Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .55),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16.w,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _AddTile(
                  onTap: onAdd,
                  icon: Icons.add_a_photo_rounded,
                  label: AppLocalizations.of(context).semAddPhoto,
                ),
              ],
            ),
          )
        else
          _AddTile(
            onTap: onAdd,
            icon: Icons.add_a_photo_rounded,
            label: AppLocalizations.of(context).semAddPhoto,
            wide: true,
          ),
        if (files.isNotEmpty) ...<Widget>[
          SizedBox(height: 10.h),
          for (final path in files)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _FileChip(
                path: path,
                onOpen: () => onOpenFile(path),
                onRemove: () => onRemove(path),
              ),
            ),
        ],
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.onTap,
    required this.icon,
    required this.label,
    this.wide = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 10.w),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onTap,
            child: SizedBox(
              width: wide ? double.infinity : 96.w,
              height: wide ? 56.h : 96.h,
              child: Icon(icon, color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({
    required this.path,
    required this.onOpen,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.semOpenFile,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onOpen,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(attachmentIcon(path), size: 20.w, color: scheme.primary),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  AttachmentUtils.fileName(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 6.w),
              Semantics(
                button: true,
                label: l10n.semRemoveFile,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.w,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientSaveButton extends StatelessWidget {
  const _GradientSaveButton({required this.onPressed, required this.saving});

  final VoidCallback? onPressed;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[scheme.primary, scheme.tertiary],
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: .4),
              blurRadius: 18.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          label: l10n.semSaveNote,
          hint: l10n.semSaveNoteHint,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (saving)
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.save_rounded, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  saving ? l10n.saving : l10n.editorSaveButton,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tag chips + inline input used by the editor.
class _TagsEditor extends StatefulWidget {
  const _TagsEditor({
    required this.tags,
    required this.onAdd,
    required this.onRemove,
  });

  final List<String> tags;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    widget.onAdd(raw);
    setState(() => _controller.clear());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.tagsSection,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: <Widget>[
            for (final tag in widget.tags)
              InputChip(
                label: Text(tag),
                deleteIcon: Icon(Icons.close_rounded, size: 16.w),
                onDeleted: () => widget.onRemove(tag),
                backgroundColor: scheme.surfaceContainerHigh,
                side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: .6),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.addTagHint,
            prefixIcon: const Icon(Icons.sell_outlined),
            isDense: true,
            suffixIcon: IconButton(
              tooltip: l10n.addTag,
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _submit(_controller.text),
            ),
          ),
          onSubmitted: _submit,
        ),
      ],
    );
  }
}

/// Markdown formatting bar: wraps the current selection (or inserts a
/// template at the caret) with the chosen syntax.
class _FormatToolbar extends StatelessWidget {
  const _FormatToolbar({required this.controller});

  final TextEditingController controller;

  void _wrap(String marker, {String placeholder = ''}) {
    final selection = controller.selection;
    final text = controller.text;
    if (!selection.isValid) {
      controller.value = TextEditingValue(
        text: '$text$marker$placeholder$marker',
        selection: TextSelection.collapsed(
          offset: text.length + marker.length + placeholder.length,
        ),
      );
      return;
    }
    final start = selection.start;
    final end = selection.end;
    final selected = text.substring(start, end);
    final replaced =
        '$marker${selected.isEmpty ? placeholder : selected}$marker';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, replaced),
      selection: TextSelection.collapsed(
        offset: start + marker.length + selected.length,
      ),
    );
  }

  void _prefixLines(String prefix) {
    final selection = controller.selection;
    final text = controller.text;
    var start = selection.start;
    if (!selection.isValid) start = text.length;
    // Extend to line start.
    while (start > 0 && text[start - 1] != '\n') {
      start--;
    }
    controller.value = TextEditingValue(
      text: text.replaceRange(start, start, prefix),
      selection: TextSelection.collapsed(
        offset: selection.baseOffset + prefix.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    Widget button(IconData icon, String tooltip, VoidCallback onTap) =>
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: tooltip,
          onPressed: () {
            Haptics.tap();
            onTap();
          },
          icon: Icon(icon, size: 20.w, color: scheme.onSurfaceVariant),
        );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            button(
              Icons.format_bold_rounded,
              l10n.formatBold,
              () => _wrap('**', placeholder: l10n.textPlaceholder),
            ),
            button(
              Icons.format_italic_rounded,
              l10n.formatItalic,
              () => _wrap('*', placeholder: l10n.textPlaceholder),
            ),
            button(
              Icons.text_fields_rounded,
              l10n.formatHeading,
              () => _prefixLines('# '),
            ),
            button(
              Icons.format_list_bulleted_rounded,
              l10n.formatBullet,
              () => _prefixLines('- '),
            ),
            button(
              Icons.check_box_outlined,
              l10n.formatCheckbox,
              () => _prefixLines('- [ ] '),
            ),
            button(
              Icons.code_rounded,
              l10n.formatCode,
              () => _wrap('`', placeholder: 'code'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminderAt,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? reminderAt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final has = reminderAt != null;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 10.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: has
            ? scheme.primaryContainer.withValues(alpha: .35)
            : scheme.surfaceContainerHigh.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: has
              ? scheme.primary.withValues(alpha: .4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.alarm_rounded,
            size: 20.w,
            color: has ? scheme.primary : scheme.onSurfaceVariant,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.reminderSection,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  has
                      ? ArabicDateTime.full(reminderAt!, l10n: l10n)
                      : l10n.noReminder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: has ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: has,
            onChanged: (_) {
              if (has) {
                onClear();
              } else {
                onPick();
              }
            },
          ),
          IconButton(
            tooltip: l10n.editReminder,
            onPressed: onPick,
            icon: Icon(
              has ? Icons.edit_calendar_rounded : Icons.add_alarm_rounded,
            ),
          ),
          if (has)
            IconButton(
              tooltip: l10n.clearReminder,
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: scheme.error),
            ),
        ],
      ),
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  const _UndoRedoButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 20.w,
        color: enabled
            ? scheme.onSurfaceVariant
            : scheme.onSurfaceVariant.withValues(alpha: .3),
      ),
    );
  }
}

class _FolderPicker extends StatefulWidget {
  const _FolderPicker({required this.folder, required this.onChanged});

  final String folder;
  final ValueChanged<String> onChanged;

  @override
  State<_FolderPicker> createState() => _FolderPickerState();
}

class _FolderPickerState extends State<_FolderPicker> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.folder,
  );

  @override
  void didUpdateWidget(covariant _FolderPicker old) {
    super.didUpdateWidget(old);
    if (old.folder != widget.folder && _controller.text != widget.folder) {
      _controller.text = widget.folder;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          l10n.folderSection,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 8.h),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: l10n.folderHint,
            prefixIcon: const Icon(Icons.folder_rounded),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 18.w),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: (v) => widget.onChanged(v.trim()),
        ),
      ],
    );
  }
}
