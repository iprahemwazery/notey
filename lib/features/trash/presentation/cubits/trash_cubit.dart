import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:notey/core/services/ui_prefs.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/trash/domain/repositories/trash_repository.dart';
import 'package:notey/features/trash/domain/usecases/empty_trash.dart';
import 'package:notey/features/trash/domain/usecases/get_trash_retention_days.dart';
import 'package:notey/features/trash/domain/usecases/load_trash.dart';
import 'package:notey/features/trash/domain/usecases/purge_notes.dart';
import 'package:notey/features/trash/domain/usecases/restore_note.dart';

class TrashState {
  final List<Note> notes;
  final bool loading;
  final int retentionDays;

  const TrashState({
    this.notes = const [],
    this.loading = true,
    this.retentionDays = UiPrefs.defaultRetentionDays,
  });

  TrashState copyWith({
    List<Note>? notes,
    bool? loading,
    int? retentionDays,
  }) {
    return TrashState(
      notes: notes ?? this.notes,
      loading: loading ?? this.loading,
      retentionDays: retentionDays ?? this.retentionDays,
    );
  }
}

/// Drives the trash bin. All persistence goes through [TrashRepository], so
/// this cubit never touches storage/reminders/images directly — it only maps
/// repository results onto [TrashState].
class TrashCubit extends Cubit<TrashState> {
  TrashCubit(TrashRepository repository)
    : _load = LoadTrash(repository),
      _retentionDays = GetTrashRetentionDays(repository),
      _restore = RestoreNote(repository),
      _purge = PurgeNotes(repository),
      _empty = EmptyTrash(repository),
      super(const TrashState());

  final LoadTrash _load;
  final GetTrashRetentionDays _retentionDays;
  final RestoreNote _restore;
  final PurgeNotes _purge;
  final EmptyTrash _empty;

  Future<void> load() async {
    final retention = await _retentionDays();
    final notes = await _load();
    emit(TrashState(notes: notes, loading: false, retentionDays: retention));
  }

  Future<void> restore(Note note) async {
    await _restore(note);
    await load();
  }

  Future<void> purge(Note note) async {
    await _purge(<Note>[note]);
    await load();
  }

  Future<void> emptyTrash() async {
    await _empty();
    await load();
  }
}
