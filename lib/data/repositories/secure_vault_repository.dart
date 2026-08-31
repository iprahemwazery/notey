import 'package:flutter/foundation.dart';

import 'package:sqflite/sqflite.dart';

import 'package:notey/core/services/vault_key_service.dart';

import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/data/database/note_database.dart';


/// SQLite-backed repository for digital vault entries.
///
/// Every write seals the sensitive payload with AES-256-CBC+HMAC before it
/// reaches disk; every read unseals it in a background isolate. Set [rootKey]
/// to a fixed provider in tests to keep the suite hermetic.
///
/// A process-wide in-memory cache of decrypted entries means re-entering the
/// vault after adding/editing/viewing entries is instant — the list is served
/// from memory and the full decrypt pass never runs twice per session.
class SecureVaultRepository {
  SecureVaultRepository({
    NoteDatabase? database,
    Future<List<int>> Function()? rootKey,
  }) : _database = database ?? NoteDatabase.instance,
       _rootKey = rootKey;

  final NoteDatabase _database;
  final Future<List<int>> Function()? _rootKey;

  /// In-memory cache of the last fully decrypted entry set, ordered
  /// newest-first (same as [getAll]). Populated on first [getAll] and kept
  /// up to date by [upsert]/[delete]. `null` when the cache is cold (never
  /// loaded, or explicitly invalidated).
  List<VaultEntry>? _cache;

  Future<List<int>> _keys() async {
    if (_rootKey != null) return _rootKey();
    return VaultKeyService().get();
  }

  /// All entries (decrypted) newest-first. Corrupt/tampered rows are skipped
  /// so a single damaged entry never bricks the whole list.
  ///
  /// The first call hits SQLite and decrypts; subsequent calls return the
  /// in-memory cache instantly. The cache is kept in sync by [upsert] and
  /// [delete], so the full decrypt path is only ever needed once per session.
  Future<List<VaultEntry>> getAll() async {
    final cached = _cache;
    if (cached != null) return cached;

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
    if (rows.isEmpty) {
      _cache = const <VaultEntry>[];
      return _cache!;
    }

    final key = await _keys();
    final entries = await VaultEntry.fromEnvelopeRows(rows, key);
    _cache = entries;
    return entries;
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
  ///
  /// The in-memory cache is patched immediately so subsequent [getAll] calls
  /// return the updated list without re-decrypting the full set from SQLite.
  Future<void> upsert(VaultEntry entry) async {
    final db = await _database.database;
    final row = await entry.toEnvelopeRow(await _keys());
    await db.insert(
      'vault_entries',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _patchCache(entry);
  }

  Future<void> delete(String id) async {
    final db = await _database.database;
    await db.delete('vault_entries', where: 'id = ?', whereArgs: <Object?>[id]);
    _evictFromCache(id);
  }

  /// Invalidates the in-memory cache. Call after bulk operations or when
  /// tests need a clean slate.
  @visibleForTesting
  void invalidateCache() => _cache = null;

  // ── Cache helpers ──────────────────────────────────────────────────────

  /// Patches the in-memory cache after an upsert (add or edit).
  void _patchCache(VaultEntry entry) {
    final c = _cache;
    if (c == null) return;
    final list = List<VaultEntry>.of(c);
    final idx = list.indexWhere((e) => e.id == entry.id);
    if (idx >= 0) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _cache = list;
  }

  /// Removes an entry from the in-memory cache by id.
  void _evictFromCache(String id) {
    final c = _cache;
    if (c == null) return;
    _cache = c.where((e) => e.id != id).toList();
  }
}