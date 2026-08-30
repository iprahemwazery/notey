import 'package:sqflite/sqflite.dart';

import 'package:notey/core/services/vault_key_service.dart';

import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/data/database/note_database.dart';


/// SQLite-backed repository for digital vault entries.
///
/// Every write seals the sensitive payload with AES-256-CBC+HMAC before it
/// reaches disk; every read unseals it in a background isolate. Set [rootKey]
/// to a fixed provider in tests to keep the suite hermetic.
class SecureVaultRepository {
  SecureVaultRepository({
    NoteDatabase? database,
    Future<List<int>> Function()? rootKey,
  }) : _database = database ?? NoteDatabase.instance,
       _rootKey = rootKey;

  final NoteDatabase _database;
  final Future<List<int>> Function()? _rootKey;

  Future<List<int>> _keys() async {
    if (_rootKey != null) return _rootKey();
    return VaultKeyService().get();
  }

  /// All entries (decrypted) newest-first. Corrupt/tampered rows are skipped
  /// so a single damaged entry never bricks the whole list.
  Future<List<VaultEntry>> getAll() async {
    final db = await _database.database;
    final rows = await db.query(
      'vault_entries',
      orderBy: 'updatedAt DESC',
      columns: <String>[
        'id',
        'category',
        'mediaType',
        'attachments',
        'envelope',
        'createdAt',
        'updatedAt',
      ],
    );
    if (rows.isEmpty) return <VaultEntry>[];

    final key = await _keys();
    // Decrypt the whole batch in a single background isolate (see
    // VaultCrypto.decryptBatch) so loading stays fast and light even as the
    // vault grows — spawning one isolate per entry would stall and can crash
    // the app on mobile.
    return VaultEntry.fromEnvelopeRows(rows, key);
  }

  Future<VaultEntry?> get(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'vault_entries',
      where: 'id = ?',
      whereArgs: <Object?>[id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return await VaultEntry.fromEnvelopeRow(rows.first, await _keys());
    } on FormatException {
      return null;
    }
  }

  /// Inserts or replaces [entry], sealing it first.
  Future<void> upsert(VaultEntry entry) async {
    final db = await _database.database;
    final row = await entry.toEnvelopeRow(await _keys());
    await db.insert(
      'vault_entries',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('vault_entries', where: 'id = ?', whereArgs: <Object?>[id]);
  }
}