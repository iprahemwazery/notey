import 'package:sqflite/sqflite.dart';

import 'package:notey/data/database/note_database.dart';

/// Raw SQLite access to the `vault_entries` table.
///
/// A data-source is deliberately dumb: it only moves opaque rows to/from the
/// database and knows nothing about [VaultEntry] or encryption. Unsealing and
/// the domain mapping happen one layer up in the repository implementation.
class VaultLocalDataSource {
  VaultLocalDataSource({NoteDatabase? database})
    : _database = database ?? NoteDatabase.instance;

  final NoteDatabase _database;

  static const List<String> _columns = <String>[
    'id',
    'category',
    'mediaType',
    'attachments',
    'envelope',
    'createdAt',
    'updatedAt',
  ];

  /// All vault rows, newest first.
  Future<List<Map<String, Object?>>> getAllRows() async {
    final db = await _database.database;
    return db.query(
      'vault_entries',
      orderBy: 'updatedAt DESC',
      columns: _columns,
    );
  }

  /// A single row by [id], or `null` when absent.
  Future<Map<String, Object?>?> getRow(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'vault_entries',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  /// Inserts or replaces a single sealed row.
  Future<void> insertRow(Map<String, Object?> row) async {
    final db = await _database.database;
    await db.insert(
      'vault_entries',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes the row with [id].
  Future<void> deleteRow(String id) async {
    final db = await _database.database;
    await db.delete(
      'vault_entries',
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }
}
