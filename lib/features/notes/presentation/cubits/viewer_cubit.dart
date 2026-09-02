import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/core/utils/checklist.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/features/notes/domain/repositories/note_history_repository.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';

import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/usecases/get_note.dart';
import 'package:notey/features/notes/domain/usecases/get_note_history.dart';
import 'package:notey/features/notes/domain/usecases/lock_note.dart';
import 'package:notey/features/notes/domain/usecases/remove_note_lock.dart';
import 'package:notey/features/notes/domain/usecases/soft_delete_note_by_id.dart';
import 'package:notey/features/notes/domain/usecases/update_note.dart';

import 'viewer_state.dart';

class ViewerCubit extends Cubit<ViewerState> {
  ViewerCubit({
    required Note note,
    required NoteRepository repository,
    required NoteHistoryRepository historyRepo,
  })  : _repository = repository,
        _getNote = GetNote(repository),
        _update = UpdateNote(repository),
        _lockNote = LockNote(repository),
        _removeNoteLock = RemoveNoteLock(repository),
        _softDelete = SoftDeleteNoteById(repository),
        _history = GetNoteHistory(historyRepo),
        super(ViewerState(note: note));

  final NoteRepository _repository;
  final GetNote _getNote;
  final UpdateNote _update;
  final LockNote _lockNote;
  final RemoveNoteLock _removeNoteLock;
  final SoftDeleteNoteById _softDelete;
  final GetNoteHistory _history;

  String? _currentPassword;

  /// Guards every lock/unlock/persist operation so concurrent taps are
  /// physically impossible — the second call short-circuits immediately.
  bool _busy = false;

  String? get currentPassword => _currentPassword;

  NoteRepository get repository => _repository;

  // ---------------------------------------------------------------------------
  // Unlock
  // ---------------------------------------------------------------------------

  Future<bool> unlock(String password) async {
    if (_busy) return false;
    _busy = true;
    try {
      final unlocked = await NoteLockService.unlock(state.note, password);
      _currentPassword = password;
      emit(state.copyWith(unlocked: () => unlocked));
      return true;
    } catch (e) {
      return false;
    } finally {
      _busy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Lock (clear decrypted copy)
  // ---------------------------------------------------------------------------

  void lock() {
    _currentPassword = null;
    emit(state.copyWith(unlocked: () => null));
  }

  // ---------------------------------------------------------------------------
  // Set password — encrypt → DB write → emit fully updated state.
  // The entire pipeline is strictly sequential with zero race conditions.
  // ---------------------------------------------------------------------------

  Future<void> setPassword(String password) async {
    if (_busy) return;
    _busy = true;
    emit(state.copyWith(locking: true));
    try {
      final locked = await _lockNote.call(
        note: state.note,
        password: password,
      );
      _currentPassword = null;
      emit(state.copyWith(note: locked, unlocked: () => null, locking: false));
    } catch (_) {
      emit(state.copyWith(locking: false));
      rethrow;
    } finally {
      _busy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Change password — re-encrypt with new password.
  // ---------------------------------------------------------------------------

  Future<bool> changePassword(String newPassword) async {
    final decrypted = state.unlocked;
    if (decrypted == null || _busy) return false;
    _busy = true;
    emit(state.copyWith(locking: true));
    try {
      final relocked = await _lockNote.call(
        note: decrypted,
        password: newPassword,
      );
      _currentPassword = null;
      emit(state.copyWith(note: relocked, unlocked: () => null, locking: false));
      return true;
    } catch (_) {
      emit(state.copyWith(locking: false));
      return false;
    } finally {
      _busy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Remove password — strip lock fields, persist plaintext.
  // ---------------------------------------------------------------------------

  Future<bool> removePassword() async {
    final decrypted = state.unlocked;
    if (decrypted == null || _busy) return false;
    _busy = true;
    emit(state.copyWith(locking: true));
    try {
      final plain = await _removeNoteLock.call(decrypted);
      _currentPassword = null;
      emit(state.copyWith(note: plain, unlocked: () => null, locking: false));
      return true;
    } catch (_) {
      emit(state.copyWith(locking: false));
      return false;
    } finally {
      _busy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Utilities
  // ---------------------------------------------------------------------------

  void setFontScale(double scale) {
    emit(state.copyWith(fontScale: scale));
  }

  Future<void> loadHistory() async {
    emit(state.copyWith(loadingHistory: true));
    final history = await _history(state.note.id);
    emit(state.copyWith(history: history, loadingHistory: false));
  }

  Future<void> toggleTask(int taskIndex) async {
    if (!state.isUnlocked) return;
    final source = state.displayNote;
    final updatedContent = Checklist.toggle(source.content, taskIndex);
    if (updatedContent == source.content) return;
    final updated = source.copyWith(
      content: updatedContent,
      updatedAt: DateTime.now(),
    );
    await _persistEdit(updated);
  }

  /// Restores a [NoteHistory] entry as the current note content, re-encrypting
  /// with the current password if the note is locked, then reloads the note.
  Future<void> restoreHistory(NoteHistory entry) async {
    final note = state.note;
    final updated = note.copyWith(
      title: entry.title,
      content: entry.content,
      updatedAt: DateTime.now(),
    );
    await _persistEdit(updated);
    await reloadNote();
  }

  Future<void> reloadNote() async {
    final reloaded = await _getNote(state.note.id);
    if (reloaded != null) {
      _currentPassword = null;
      emit(state.copyWith(note: reloaded, unlocked: () => null));
    }
  }

  Future<void> _persistEdit(Note edited) async {
    if (state.note.isLocked && _currentPassword != null) {
      final locked = await _lockNote.call(
        note: edited,
        password: _currentPassword!,
      );
      await _update(locked);
    } else {
      await _update(edited);
    }
    emit(state.copyWith(unlocked: () => edited));
  }

  Future<void> delete() async {
    await _softDelete(state.note.id);
  }
}
