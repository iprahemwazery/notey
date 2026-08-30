import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:notey/core/constants/app_constants.dart';


/// SQLite wrapper for the notes table. Works on mobile & desktop.
class NoteDatabase {
  NoteDatabase({String? path, this.inMemory = false}) : _overridePath = path;

  static final NoteDatabase instance = NoteDatabase();

  final String? _overridePath;
  final bool inMemory;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _open() async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String dbPath;
    if (inMemory) {
      dbPath = inMemoryDatabasePath;
    } else if (_overridePath case final path?) {
      dbPath = path;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = p.join(dir.path, AppConstants.dbName);
    }

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppConstants.dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  /// Perf/reliability pragmas: WAL journal + faster sync + busy timeout.
  Future<void> _onConfigure(Database db) async {
    try {
      await db.execute('PRAGMA journal_mode = WAL');
      await db.execute('PRAGMA synchronous = NORMAL');
      await db.execute('PRAGMA busy_timeout = 5000');
    } on Exception {
      // Ignore — not all platforms support these pragmas.
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        images TEXT NOT NULL DEFAULT '[]',
        colorIndex INTEGER NOT NULL DEFAULT 0,
        pinned INTEGER NOT NULL DEFAULT 0,
        isLocked INTEGER NOT NULL DEFAULT 0,
        lockSalt TEXT,
        deletedAt INTEGER,
        tags TEXT NOT NULL DEFAULT '[]',
        reminderAt INTEGER,
        folder TEXT NOT NULL DEFAULT '',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_notes_updatedAt ON notes(updatedAt DESC)',
    );
    await _createHistoryTable(db);
    await _createVaultTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN pinned INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isLocked INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE notes ADD COLUMN lockSalt TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN deletedAt INTEGER');
    }
    if (oldVersion < 5) {
      // JSON array of tag strings.
      await db.execute(
        "ALTER TABLE notes ADD COLUMN tags TEXT NOT NULL DEFAULT '[]'",
      );
      // Epoch millis of an optional reminder notification.
      await db.execute('ALTER TABLE notes ADD COLUMN reminderAt INTEGER');
    }
    if (oldVersion < 6) {
      await _createHistoryTable(db);
    }
    if (oldVersion < 7) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN folder TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 8) {
      await _createVaultTable(db);
    }
  }

  Future<void> _createVaultTable(Database db) async {
    await db.execute('''
      CREATE TABLE vault_entries (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        mediaType TEXT NOT NULL DEFAULT 'none',
        attachments TEXT NOT NULL DEFAULT '[]',
        envelope TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_vault_updatedAt ON vault_entries(updatedAt DESC)',
    );
  }

  Future<void> _createHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE note_history (
        id TEXT PRIMARY KEY,
        noteId TEXT NOT NULL,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        timestamp INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_history_noteId ON note_history(noteId, timestamp DESC)',
    );
  }
}
