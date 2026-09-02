import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/notes/data/models/note_history_model.dart';
import 'package:notey/features/notes/data/models/note_model.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_history.dart';
import 'package:notey/features/notes/domain/entities/note_search_result.dart';

/// Low-level SQLite gateway for the `notes` and `note_history` tables.
///
/// This class is deliberately "dumb": it knows only about rows and columns,
/// mapping them through [NoteModel]/[NoteHistoryModel]. No business rules,
/// no crypto — those live in the repository/usecase layers.
class NoteLocalDataSource {
  NoteLocalDataSource({NoteDatabase? database})
      : _database = database ?? NoteDatabase.instance;

  final NoteDatabase _database;

  Future<List<Note>> getNotes({String? search, String? folder}) async {
    final db = await _database.database;
    final term = search?.trim() ?? '';
    final conditions = <String>['deletedAt IS NULL'];
    final args = <String>[];

    if (term.isNotEmpty) {
      final pattern = '%${_escapeLike(term)}%';
      conditions.add(r"(title LIKE ? ESCAPE '\' OR content LIKE ? ESCAPE '\')");
      args.addAll(<String>[pattern, pattern]);
    }
    if (folder != null && folder.isNotEmpty) {
      conditions.add('folder = ?');
      args.add(folder);
    }

    final where = conditions.join(' AND ');
    final rows = await db.query(
      'notes',
      where: where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updatedAt DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<List<String>> getFolders() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT folder FROM notes WHERE deletedAt IS NULL AND folder != '' ORDER BY folder ASC",
    );
    return rows.map((r) => r['folder'] as String).toList();
  }

  Future<List<Note>> getAllNotesIncludingDeleted() async {
    final db = await _database.database;
    final rows = await db.query('notes', orderBy: 'updatedAt DESC');
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<List<Note>> getDeletedNotes() async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'deletedAt IS NOT NULL',
      orderBy: 'deletedAt DESC',
    );
    return rows.map(NoteModel.fromMap).toList();
  }

  Future<Note?> getNote(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: <String>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : NoteModel.fromMap(rows.first);
  }

  Future<void> insert(Note note) async {
    final db = await _database.database;
    await db.insert('notes', NoteModel.toMap(note));
  }

  Future<void> insertAll(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();
    for (final note in notes) {
      batch.insert('notes', NoteModel.toMap(note));
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Note note) async {
    final db = await _database.database;
    await db.update(
      'notes',
      NoteModel.toMap(note),
      where: 'id = ?',
      whereArgs: <String>[note.id],
    );
  }

  Future<void> updateAll(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();
    for (final note in notes) {
      batch.update(
        'notes',
        NoteModel.toMap(note),
        where: 'id = ?',
        whereArgs: <String>[note.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> softDelete(String id, {DateTime? at}) async {
    final db = await _database.database;
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    await db.update(
      'notes',
      <String, Object?>{'deletedAt': now, 'pinned': 0},
      where: 'id = ?',
      whereArgs: <String>[id],
    );
  }

  Future<void> softDeleteAll(List<String> ids, {DateTime? at}) async {
    if (ids.isEmpty) return;
    final db = await _database.database;
    final now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'notes',
        <String, Object?>{'deletedAt': now, 'pinned': 0},
        where: 'id = ?',
        whereArgs: <String>[id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> restore(String id) => _restoreAll(<String>[id]);

  Future<void> restoreAll(List<String> ids) => _restoreAll(ids);

  Future<void> _restoreAll(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update(
        'notes',
        <String, Object?>{'deletedAt': null},
        where: 'id = ?',
        whereArgs: <String>[id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> purge(String id) => _purgeWhere('id = ?', <Object?>[id]);

  Future<void> purgeAllDeleted() =>
      _purgeWhere('deletedAt IS NOT NULL', const <Object?>[]);

  Future<List<Note>> purgeExpired(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age).millisecondsSinceEpoch;
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'deletedAt IS NOT NULL AND deletedAt < ?',
      whereArgs: <Object?>[cutoff],
    );
    if (rows.isEmpty) return const <Note>[];
    final expired = rows.map(NoteModel.fromMap).toList();
    await _purgeWhere('deletedAt IS NOT NULL AND deletedAt < ?', <Object?>[
      cutoff,
    ]);
    return expired;
  }

  Future<void> _purgeWhere(String where, List<Object?> args) async {
    final db = await _database.database;
    await db.delete('notes', where: where, whereArgs: args);
  }

  Future<List<NoteSearchMatch>> attachmentSearchMatches({
    required Set<String> matchedIds,
    required String termLower,
    required String? folder,
    required String term,
  }) async {
    final db = await _database.database;
    final conditions = <String>['deletedAt IS NULL'];
    final args = <Object?>[];
    if (folder != null && folder.isNotEmpty) {
      conditions.add('folder = ?');
      args.add(folder);
    }
    final rows = await db.query(
      'notes',
      where: conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'updatedAt DESC',
    );
    final results = <NoteSearchMatch>[];
    for (final note in rows.map(NoteModel.fromMap)) {
      if (matchedIds.contains(note.id) || note.isLocked) continue;
      final fileMatch = await _firstFileMatch(note, termLower);
      if (fileMatch == null) continue;
      matchedIds.add(note.id);
      results.add(
        NoteSearchMatch(
          note: note,
          location: SearchMatchLocation.attachment,
          preview: searchSnippetAround(fileMatch.text, term),
          fileName: fileMatch.name,
        ),
      );
    }
    return results;
  }

  /// Text extensions we are willing to read and search inside.
  static const Set<String> _textExtensions = <String>{
    '.txt', '.md', '.markdown', '.log', '.csv', '.tsv', '.json', '.xml',
    '.html', '.htm', '.yaml', '.yml', '.ini', '.cfg', '.conf', '.sh',
    '.sql', '.py', '.js', '.ts', '.java', '.c', '.cpp', '.h', '.dart',
  };

  /// Files bigger than this are skipped to keep search fast.
  static const int _maxSearchFileBytes = 512 * 1024;

  Future<_FileMatch?> _firstFileMatch(Note note, String termLower) async {
    for (final path in note.attachments) {
      final ext = p.extension(path).toLowerCase();
      if (!_textExtensions.contains(ext)) continue;
      final file = File(path);
      try {
        if (!await file.exists()) continue;
        if (await file.length() > _maxSearchFileBytes) continue;
        final bytes = await file.readAsBytes();
        final text = const Utf8Decoder(allowMalformed: true).convert(bytes);
        if (text.toLowerCase().contains(termLower)) {
          return _FileMatch(name: p.basename(path), text: text);
        }
      } on Exception {
        // Unreadable/binary file — skip it.
      } on ArgumentError {
        // Not valid UTF-8 — skip it.
      }
    }
    return null;
  }

  // ---- note_history ----

  Future<void> logHistory(NoteHistory entry) async {
    final db = await _database.database;
    await db.insert('note_history', NoteHistoryModel.toMap(entry));
  }

  Future<List<NoteHistory>> getHistory(String noteId) async {
    final db = await _database.database;
    final rows = await db.query(
      'note_history',
      where: 'noteId = ?',
      whereArgs: <String>[noteId],
      orderBy: 'timestamp DESC',
    );
    return rows.map(NoteHistoryModel.fromMap).toList();
  }

  Future<void> deleteHistory(String noteId) async {
    final db = await _database.database;
    await db.delete(
      'note_history',
      where: 'noteId = ?',
      whereArgs: <String>[noteId],
    );
  }

  Future<void> trimHistory(String noteId, {int keep = 30}) async {
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

  /// Escapes LIKE wildcards so user input is matched literally.
  static String _escapeLike(String term) => term
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// A matched text file inside a note (path + content to build the snippet).
class _FileMatch {
  const _FileMatch({required this.name, required this.text});

  final String name;
  final String text;
}
