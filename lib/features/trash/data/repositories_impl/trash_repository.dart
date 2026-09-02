import 'package:notey/core/services/reminder_service.dart';
import 'package:notey/core/services/ui_prefs.dart';
import 'package:notey/data/services/image_store.dart';
import 'package:notey/features/notes/data/repositories_impl/note_history_repository.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/domain/usecases/delete_note_history.dart';
import 'package:notey/features/trash/domain/repositories/trash_repository.dart';

/// Concrete [TrashRepository] backed by the notes repository plus the shared
/// [ImageStore] and [ReminderService].
///
/// Simply orchestrates the existing notes/reminder/image primitives so the
/// trash screen stays a thin shell over its cubit.
class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl({
    required NoteRepository noteRepository,
    ImageStore? imageStore,
  }) : _notes = noteRepository,
       _images = imageStore ?? ImageStore(),
       _deleteHistory = DeleteNoteHistory(NoteHistoryRepositoryImpl());

  final NoteRepository _notes;
  final ImageStore _images;
  final DeleteNoteHistory _deleteHistory;

  @override
  Future<int> retentionDays() => UiPrefs.trashRetentionDays();

  @override
  Future<List<Note>> load() async {
    final retention = await UiPrefs.trashRetentionDays();
    final expired = await _notes.purgeExpired(Duration(days: retention));
    await ReminderService.cancelAll(expired.map((n) => n.id));
    for (final note in expired) {
      await _deleteFiles(note);
      await _deleteHistory(note.id);
    }
    return _notes.getDeletedNotes();
  }

  @override
  Future<void> restore(Note note) async {
    await _notes.restore(note.id);
    await ReminderService.sync(note);
  }

  @override
  Future<void> purge(List<Note> notes) async {
    for (final note in notes) {
      await _notes.purge(note.id);
      await ReminderService.cancel(note.id);
      await _deleteFiles(note);
      await _deleteHistory(note.id);
    }
  }

  @override
  Future<void> empty() async {
    final trashed = await _notes.emptyTrash();
    await ReminderService.cancelAll(trashed.map((n) => n.id));
    for (final note in trashed) {
      await _deleteFiles(note);
      await _deleteHistory(note.id);
    }
  }

  Future<void> _deleteFiles(Note note) async {
    for (final path in note.attachments) {
      await _images.delete(path);
    }
  }
}
