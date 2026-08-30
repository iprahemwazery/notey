import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/features/notes/model/note.dart';


class TrashState {
  final List<Note> notes;
  final bool loading;
  final int retentionDays;

  const TrashState({
    this.notes = const [],
    this.loading = true,
    this.retentionDays = 30,
  });

  TrashState copyWith({List<Note>? notes, bool? loading, int? retentionDays}) {
    return TrashState(
      notes: notes ?? this.notes,
      loading: loading ?? this.loading,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }
}

class TrashCubit extends Cubit<TrashState> {
  TrashCubit(this._repository) : super(const TrashState());
  final NoteRepository _repository;

  Future<void> load() async {
    final retention = await UiPrefs.trashRetentionDays();
    await _repository.purgeExpired(Duration(days: retention));
    final notes = await _repository.getDeletedNotes();
    emit(TrashState(notes: notes, loading: false, retentionDays: retention));
  }

  Future<void> restore(String id) async {
    await _repository.restore(id);
    await load();
  }

  Future<void> purge(String id) async {
    await _repository.purge(id);
    await load();
  }

  Future<void> emptyTrash() async {
    await _repository.emptyTrash();
    await load();
  }
}
