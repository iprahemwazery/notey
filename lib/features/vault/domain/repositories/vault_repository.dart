import 'package:notey/features/vault/domain/entities/vault_entry.dart';

/// Abstract contract for reading and writing vault entries.
///
/// The presentation layer depends on this interface (never on a concrete data
/// implementation), which keeps the UI decoupled from where/how entries are
/// stored and how they are encrypted.
abstract interface class VaultRepository {
  /// All entries (decrypted) newest-first. Corrupt/tampered rows are skipped
  /// so a single damaged entry never bricks the whole list.
  Future<List<VaultEntry>> getAll();

  /// Looks up a single entry by [id]; `null` when missing or tampered.
  Future<VaultEntry?> get(String id);

  /// Inserts or replaces [entry], sealing/encrypting it first.
  Future<void> upsert(VaultEntry entry);

  /// Deletes the entry with [id].
  Future<void> delete(String id);

  /// Invalidates any in-memory cache. After bulk operations or when tests need
  /// a clean slate.
  void invalidateCache();
}
