import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/notes/data/datasources/note_local_data_source.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_search_result.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

/// SQL-backed implementation of [NoteRepository].
///
/// Acts as the boundary between the domain port and the [NoteLocalDataSource]
/// tables. Contains no SQL and no crypto of its own — those are delegated to
/// the datasource and the encryption services used by the callers.
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({NoteDatabase? database})
      : _dataSource =
            NoteLocalDataSource(database: database ?? NoteDatabase.instance);

  final NoteLocalDataSource _dataSource;

  @override
  Future<List<Note>> getNotes({String? search, String? folder}) =>
      _dataSource.getNotes(search: search, folder: folder);

  @override
  Future<List<String>> getFolders() => _dataSource.getFolders();

  @override
  Future<List<NoteSearchMatch>> searchNotes({
    required String search,
    String? folder,
  }) async {
    final term = search.trim();
    if (term.isEmpty) return const <NoteSearchMatch>[];
    final termLower = term.toLowerCase();

    // Title/body matches reuse the SQL path (and the same fake used in tests).
    final baseNotes = await getNotes(search: term, folder: folder);
    final results = <NoteSearchMatch>[];
    final matchedIds = <String>{};
    for (final note in baseNotes) {
      matchedIds.add(note.id);
      // Locked notes are encrypted: their content can't be searched and must
      // never leak ciphertext into a snippet.
      if (note.isLocked) continue;
      if (note.content.toLowerCase().contains(termLower)) {
        results.add(
          NoteSearchMatch(
            note: note,
            location: SearchMatchLocation.content,
            preview: searchSnippetAround(note.content, term),
          ),
        );
      } else {
        results.add(
          NoteSearchMatch(
            note: note,
            location: SearchMatchLocation.title,
            preview: firstContentLine(note.content),
          ),
        );
      }
    }

    // Attachment-body matches for notes that didn't match title/content.
    final fileMatches = await _dataSource.attachmentSearchMatches(
      matchedIds: matchedIds,
      termLower: termLower,
      folder: folder,
      term: term,
    );
    results.addAll(fileMatches);

    results.sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
    return results;
  }

  @override
  Future<List<Note>> getAllNotesIncludingDeleted() =>
      _dataSource.getAllNotesIncludingDeleted();

  @override
  Future<List<Note>> getDeletedNotes() => _dataSource.getDeletedNotes();

  @override
  Future<Note?> getNote(String id) => _dataSource.getNote(id);

  @override
  Future<void> insert(Note note) => _dataSource.insert(note);

  @override
  Future<void> insertAll(List<Note> notes) => _dataSource.insertAll(notes);

  @override
  Future<void> update(Note note) => _dataSource.update(note);

  @override
  Future<void> updateAll(List<Note> notes) => _dataSource.updateAll(notes);

  @override
  Future<void> softDelete(String id, {DateTime? at}) =>
      _dataSource.softDelete(id, at: at);

  @override
  Future<void> softDeleteAll(List<String> ids, {DateTime? at}) =>
      _dataSource.softDeleteAll(ids, at: at);

  @override
  Future<void> restore(String id) => _dataSource.restore(id);

  @override
  Future<void> restoreAll(List<String> ids) => _dataSource.restoreAll(ids);

  @override
  Future<void> purge(String id) => _dataSource.purge(id);

  @override
  Future<List<Note>> emptyTrash() async {
    final trashed = await _dataSource.getDeletedNotes();
    await _dataSource.purgeAllDeleted();
    return trashed;
  }

  @override
  Future<List<Note>> purgeExpired(Duration age, {DateTime? now}) =>
      _dataSource.purgeExpired(age, now: now);
}
