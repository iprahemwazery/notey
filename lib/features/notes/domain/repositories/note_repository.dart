import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_search_result.dart';

/// Port – repository exposing all note CRUD operations.
///
/// Deletion is soft ([Note.deletedAt]); purging removes rows for good.
/// The concrete SQL-backed implementation lives in the data layer.
abstract interface class NoteRepository {
  /// Returns all non-deleted notes, newest first. Filters by `search` and/or `folder`.
  Future<List<Note>> getNotes({String? search, String? folder});

  /// Returns all distinct non-empty folder names used by active notes.
  Future<List<String>> getFolders();

  /// Advanced search (like WhatsApp): finds notes matching [search] in the
  /// title, in the body, or inside attached text files. Each hit carries the
  /// note plus where the match happened and a snippet of the matched text.
  Future<List<NoteSearchMatch>> searchNotes({
    required String search,
    String? folder,
  });

  /// Every note including trashed ones (used by backup & orphan sweeps).
  Future<List<Note>> getAllNotesIncludingDeleted();

  /// Notes currently in the trash, most recently deleted first.
  Future<List<Note>> getDeletedNotes();

  Future<Note?> getNote(String id);

  Future<void> insert(Note note);

  /// Inserts many notes in a single transaction.
  Future<void> insertAll(List<Note> notes);

  Future<void> update(Note note);

  /// Updates many notes in a single transaction.
  Future<void> updateAll(List<Note> notes);

  /// Soft-deletes a note — it stays restorable from the trash.
  Future<void> softDelete(String id, {DateTime? at});

  /// Soft-deletes many notes in one transaction.
  Future<void> softDeleteAll(List<String> ids, {DateTime? at});

  /// Moves a trashed note back to the main list.
  Future<void> restore(String id);

  /// Restores many trashed notes in one transaction.
  Future<void> restoreAll(List<String> ids);

  /// Permanently deletes a note row.
  Future<void> purge(String id);

  /// Permanently deletes every trashed note. Returns what was removed so
  /// the caller can clean up image files.
  Future<List<Note>> emptyTrash();

  /// Auto-purges notes trashed before [age]. Returns the removed notes.
  Future<List<Note>> purgeExpired(Duration age, {DateTime? now});
}
