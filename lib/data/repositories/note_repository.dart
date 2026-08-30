import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:notey/features/notes/model/note.dart';

import 'package:notey/features/notes/model/note_search_result.dart';

import 'package:notey/data/database/note_database.dart';


/// Repository exposing all note CRUD operations.
/// Deletion is soft ([Note.deletedAt]); purging removes rows for good.
class NoteRepository {
  NoteRepository({NoteDatabase? database})
    : _database = database ?? NoteDatabase.instance;

  final NoteDatabase _database;

  /// Returns all non-deleted notes, newest first. Filters by `search` and/or `folder`.
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
    return rows.map(Note.fromMap).toList();
  }

  /// Returns all distinct non-empty folder names used by active notes.
  Future<List<String>> getFolders() async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      "SELECT DISTINCT folder FROM notes WHERE deletedAt IS NULL AND folder != '' ORDER BY folder ASC",
    );
    return rows.map((r) => r['folder'] as String).toList();
  }

  /// Advanced search (like WhatsApp): finds notes matching [search] in the
  /// title, in the body, or inside attached text files. Each hit carries the
  /// note plus where the match happened and a snippet of the matched text.
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
    for (final note in rows.map(Note.fromMap)) {
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

    results.sort((a, b) => b.note.updatedAt.compareTo(a.note.updatedAt));
    return results;
  }

  /// Text extensions we are willing to read and search inside.
  static const Set<String> _textExtensions = <String>{
    '.txt',
    '.md',
    '.markdown',
    '.log',
    '.csv',
    '.tsv',
    '.json',
    '.xml',
    '.html',
    '.htm',
    '.yaml',
    '.yml',
    '.ini',
    '.cfg',
    '.conf',
    '.sh',
    '.sql',
    '.py',
    '.js',
    '.ts',
    '.java',
    '.c',
    '.cpp',
    '.h',
    '.dart',
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

  /// Every note including trashed ones (used by backup & orphan sweeps).
  Future<List<Note>> getAllNotesIncludingDeleted() async {
    final db = await _database.database;
    final rows = await db.query('notes', orderBy: 'updatedAt DESC');
    return rows.map(Note.fromMap).toList();
  }

  /// Notes currently in the trash, most recently deleted first.
  Future<List<Note>> getDeletedNotes() async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'deletedAt IS NOT NULL',
      orderBy: 'deletedAt DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<Note?> getNote(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: <String>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : Note.fromMap(rows.first);
  }

  Future<void> insert(Note note) async {
    final db = await _database.database;
    await db.insert('notes', note.toMap());
  }

  /// Inserts many notes in a single transaction.
  Future<void> insertAll(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();
    for (final note in notes) {
      batch.insert('notes', note.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> update(Note note) async {
    final db = await _database.database;
    await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: <String>[note.id],
    );
  }

  /// Updates many notes in a single transaction.
  Future<void> updateAll(List<Note> notes) => _batchWrite(notes);

  Future<void> _batchWrite(List<Note> notes) async {
    if (notes.isEmpty) return;
    final db = await _database.database;
    final batch = db.batch();
    for (final note in notes) {
      batch.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: <String>[note.id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Soft-deletes a note — it stays restorable from the trash.
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

  /// Soft-deletes many notes in one transaction.
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

  /// Moves a trashed note back to the main list.
  Future<void> restore(String id) => _restoreAll(<String>[id]);

  /// Restores many trashed notes in one transaction.
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

  /// Permanently deletes a note row. Use [deleteImages] to free its files.
  Future<void> purge(String id) => _purgeWhere('id = ?', <Object?>[id]);

  /// Permanently deletes every trashed note. Returns what was removed so
  /// the caller can clean up image files.
  Future<List<Note>> emptyTrash() async {
    final trashed = await getDeletedNotes();
    await _purgeWhere('deletedAt IS NOT NULL', const <Object?>[]);
    return trashed;
  }

  /// Auto-purges notes trashed before [cutoff]. Returns the removed notes.
  Future<List<Note>> purgeExpired(Duration age, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(age).millisecondsSinceEpoch;
    final db = await _database.database;
    final rows = await db.query(
      'notes',
      where: 'deletedAt IS NOT NULL AND deletedAt < ?',
      whereArgs: <Object?>[cutoff],
    );
    if (rows.isEmpty) return const <Note>[];
    final expired = rows.map(Note.fromMap).toList();
    await _purgeWhere('deletedAt IS NOT NULL AND deletedAt < ?', <Object?>[
      cutoff,
    ]);
    return expired;
  }

  Future<void> _purgeWhere(String where, List<Object?> args) async {
    final db = await _database.database;
    await db.delete('notes', where: where, whereArgs: args);
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
