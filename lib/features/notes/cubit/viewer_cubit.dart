import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/core/utils/checklist.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/data/repositories/note_history_repository.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/features/notes/model/note.dart';

import 'viewer_state.dart';

class ViewerCubit extends Cubit<ViewerState> {
  ViewerCubit({
    required Note note,
    required NoteRepository repository,
    required NoteHistoryRepository historyRepo,
  })  : _repository = repository,
        _historyRepo = historyRepo,
        super(ViewerState(note: note));

  final NoteRepository _repository;
  final NoteHistoryRepository _historyRepo;

  String? _currentPassword;

  String? get currentPassword => _currentPassword;

  NoteRepository get repository => _repository;

  Future<bool> unlock(String password) async {
    try {
      final unlocked = await NoteLockService.unlock(state.note, password);
      _currentPassword = password;
      emit(state.copyWith(unlocked: () => unlocked));
      return true;
    } catch (e) {
      return false;
    }
  }

  void lock() {
    _currentPassword = null;
    emit(state.copyWith(unlocked: () => null));
  }

  void setFontScale(double scale) {
    emit(state.copyWith(fontScale: scale));
  }

  Future<void> loadHistory() async {
    emit(state.copyWith(loadingHistory: true));
    final history = await _historyRepo.getHistory(state.note.id);
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

  Future<void> reloadNote() async {
    final reloaded = await _repository.getNote(state.note.id);
    if (reloaded != null) {
      _currentPassword = null;
      emit(state.copyWith(note: reloaded, unlocked: () => null));
    }
  }

  Future<void> _persistEdit(Note edited) async {
    if (state.note.isLocked && _currentPassword != null) {
      final locked = await NoteLockService.lock(edited, _currentPassword!);
      await _repository.update(locked);
    } else {
      await _repository.update(edited);
    }
    emit(state.copyWith(unlocked: () => edited));
  }

  Future<void> setPassword(String password) async {
    final locked = await NoteLockService.lock(state.note, password);
    await _repository.update(locked);
    _currentPassword = null;
    emit(state.copyWith(note: locked, unlocked: () => null));
  }

  /// Ensures note is decrypted, then re-encrypts with [newPassword].
  Future<bool> changePassword(String newPassword) async {
    final decrypted = state.unlocked;
    if (decrypted == null) return false;
    final relocked = await NoteLockService.lock(decrypted, newPassword);
    await _repository.update(relocked);
    _currentPassword = null;
    emit(state.copyWith(note: relocked, unlocked: () => null));
    return true;
  }

  Future<bool> removePassword() async {
    final decrypted = state.unlocked;
    if (decrypted == null) return false;
    final plain = await NoteLockService.removeLock(decrypted);
    await _repository.update(plain);
    _currentPassword = null;
    emit(state.copyWith(note: plain, unlocked: () => null));
    return true;
  }

  Future<void> delete() async {
    await _repository.softDelete(state.note.id);
  }
}
