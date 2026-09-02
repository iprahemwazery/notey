import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/usecases/save_note.dart';
import 'package:notey/features/notes/domain/usecases/soft_delete_note.dart';

import 'editor_state.dart';

class _Snapshot {
  const _Snapshot({required this.title, required this.content});
  final String title;
  final String content;
}

class EditorCubit extends Cubit<EditorState> {
  EditorCubit({
    required NoteRepository repository,
    required NoteHistoryRepository historyRepo,
    Note? existingNote,
  })  : _save = SaveNote(repository, historyRepo),
        _softDelete = SoftDeleteNote(repository),
        super(EditorState(
          isEditing: existingNote != null,
          note: existingNote,
          title: existingNote?.title ?? '',
          content: existingNote?.content ?? '',
          attachments: existingNote?.attachments ?? const [],
          tags: existingNote?.tags ?? const [],
          colorIndex: existingNote?.colorIndex ?? 0,
          reminderAt: existingNote?.reminderAt,
          folder: existingNote?.folder ?? '',
        )) {
    _originalTitle = existingNote?.title ?? '';
    _originalContent = existingNote?.content ?? '';
    _originalAttachments = List<String>.of(existingNote?.attachments ?? const []);
    // Seed the undo stack with the initial state.
    _undoStack.add(_Snapshot(title: state.title, content: state.content));
  }

  final SaveNote _save;
  final SoftDeleteNote _softDelete;
  late String _originalTitle;
  late String _originalContent;
  late List<String> _originalAttachments;

  /// Undo/redo stacks — max 50 snapshots each.
  final List<_Snapshot> _undoStack = <_Snapshot>[];
  final List<_Snapshot> _redoStack = <_Snapshot>[];
  static const int _maxStack = 50;

  /// The last snapshot pushed, used to avoid duplicate consecutive entries.
  _Snapshot? _lastPushed;

  void _safeEmit(EditorState newState) {
    if (!isClosed) emit(newState);
  }

  /// Call after a burst of typing to snapshot the current title+content
  /// for undo. Deduplicates consecutive identical snapshots.
  void pushSnapshot() {
    final snap = _Snapshot(title: state.title, content: state.content);
    if (_lastPushed != null &&
        _lastPushed!.title == snap.title &&
        _lastPushed!.content == snap.content) {
      return;
    }
    _undoStack.add(snap);
    if (_undoStack.length > _maxStack) _undoStack.removeAt(0);
    _redoStack.clear();
    _lastPushed = snap;
    _safeEmit(state.copyWith(canUndo: true, canRedo: false));
  }

  void undo() {
    if (_undoStack.length <= 1) return;
    final current = _undoStack.removeLast();
    _redoStack.add(current);
    final previous = _undoStack.last;
    _lastPushed = previous;
    _safeEmit(state.copyWith(
      title: previous.title,
      content: previous.content,
      canUndo: _undoStack.length > 1,
      canRedo: true,
    ));
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final next = _redoStack.removeLast();
    _undoStack.add(next);
    _lastPushed = next;
    _safeEmit(state.copyWith(
      title: next.title,
      content: next.content,
      canUndo: true,
      canRedo: _redoStack.isNotEmpty,
    ));
  }

  void updateTitle(String value) => _safeEmit(state.copyWith(title: value));
  void updateContent(String value) => _safeEmit(state.copyWith(content: value));
  void setColor(int index) => _safeEmit(state.copyWith(colorIndex: index));
  
  void setReminder(DateTime? dt) => _safeEmit(state.copyWith(reminderAt: () => dt));

  void setFolder(String value) => _safeEmit(state.copyWith(folder: value));

  void addAttachment(String path) {
    _safeEmit(state.copyWith(attachments: [...state.attachments, path]));
  }

  void removeAttachment(String path) {
    _safeEmit(state.copyWith(
      attachments: state.attachments.where((p) => p != path).toList(),
    ));
  }

  void addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty || state.tags.contains(trimmed)) return;
    _safeEmit(state.copyWith(tags: [...state.tags, trimmed]));
  }

  void removeTag(String tag) {
    _safeEmit(state.copyWith(tags: state.tags.where((t) => t != tag).toList()));
  }

  void clearError() {
    _safeEmit(state.copyWith(errorMessage: () => null));
  }

  /// Adopts a note that was persisted eagerly (e.g. a brand-new note locked
  /// immediately from the protection menu). Switches the editor into
  /// edit-mode for that note so later saves update it instead of inserting a
  /// duplicate.
  void adoptNote(Note note) {
    _originalTitle = note.title;
    _originalContent = note.content;
    _originalAttachments = List<String>.of(note.attachments);
    _safeEmit(state.copyWith(isEditing: true, note: note));
  }

  bool get hasChanges {
    return state.title != _originalTitle ||
        state.content != _originalContent ||
        state.attachments.join(',') != _originalAttachments.join(',');
  }

  Future<bool> save() async {
    if (state.saving) return false;
    if (state.title.trim().isEmpty) return false;

    _safeEmit(state.copyWith(saving: true, errorMessage: () => null));
    try {
      await _save.call(
        isEditing: state.isEditing,
        existing: state.note,
        title: state.title,
        content: state.content,
        attachments: state.attachments,
        tags: state.tags,
        colorIndex: state.colorIndex,
        reminderAt: state.reminderAt,
        folder: state.folder,
      );
      _safeEmit(state.copyWith(saving: false, allowPop: true));
      return true;
    } catch (e) {
      _safeEmit(state.copyWith(
        saving: false,
        errorMessage: () => e.toString(),
      ));
      return false;
    }
  }

  Future<void> delete() async {
    if (state.note != null) {
      await _softDelete(state.note!);
    }
  }
}
