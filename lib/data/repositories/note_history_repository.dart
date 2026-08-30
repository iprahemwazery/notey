import 'package:notey/features/notes/model/note_history.dart';

import 'package:notey/data/database/note_database.dart';


/// Repository for note edit history CRUD operations.
class NoteHistoryRepository {
  NoteHistoryRepository({NoteDatabase? database})
      : _database = database ?? NoteDatabase.instance;

  final NoteDatabase _database;

  /// Logs a new history snapshot for a note.
  Future<void> log(NoteHistory entry) async {
    final db = await _database.database;
    await db.insert('note_history', entry.toMap());
  }

  /// Returns history entries for a note, newest first.
  Future<List<NoteHistory>> getHistory(String noteId) async {
    final db = await _database.database;
    final rows = await db.query(
      'note_history',
      where: 'noteId = ?',
      whereArgs: <String>[noteId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(NoteHistory.fromMap).toList();
  }

  /// Deletes all history entries for a note.
  Future<void> deleteAll(String noteId) async {
    final db = await _database.database;
    await db.delete(
      'note_history',
      where: 'noteId = ?',
      whereArgs: <String>[noteId],
    );
  }

  /// Deletes the oldest entries for a note, keeping at most [keep] snapshots.
  Future<void> trim(String noteId, {int keep = 30}) async {
    final db = await _database.database;
    await db.rawDelete(
      '''
      DELETE FROM note_history
      WHERE noteId = ?
        AND id NOT IN (
          SELECT id FROM note_history
          WHERE noteId = ?
          ORDER BY timestamp DESC
          LIMIT ?
        )
      ''',
      <Object?>[noteId, noteId, keep],
    );
  }
}
