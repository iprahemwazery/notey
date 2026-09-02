import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';
import 'package:notey/features/vault/domain/usecases/delete_vault_entry.dart';
import 'package:notey/features/vault/domain/usecases/load_vault_entries.dart';
import 'package:notey/features/vault/domain/usecases/save_vault_entry.dart';

import 'vault_state.dart';

/// Drives the digital vault: loads decrypted entries off the repository,
/// filters them across the category chips and persists add/edit/delete.
///
/// All mutations are **optimistic**: the UI reflects the change instantly and
/// the SQLite write (encryption + insert) happens in the background. On a
/// write failure the change is rolled back so the UI never shows a row that
/// is not really on disk.
class VaultCubit extends Cubit<VaultState> {
  VaultCubit(VaultRepository repository)
    : _load = LoadVaultEntries(repository),
      _save = SaveVaultEntry(repository),
      _delete = DeleteVaultEntry(repository),
      super(const VaultState());

  final LoadVaultEntries _load;
  final SaveVaultEntry _save;
  final DeleteVaultEntry _delete;

  /// In-flight persistence mutations keyed by entry id, used to decide which
  /// concurrent mutation to roll back if its write fails. Kept small and is
  /// only consulted by the rollback path.
  final Set<String> _pendingWrites = <String>{};

  /// Loads vault entries. A full-screen loading state is only shown for the
  /// initial empty-load or when explicitly requested; regular refreshes stay
  /// silent so the vault stays smooth while navigating in and out of entries.
  ///
  /// Because the repository now caches decrypted entries in memory, this is
  /// effectively free on every navigation after the first cold load.
  Future<void> load({bool silent = false}) async {
    final hasData = state.phase == VaultPhase.ready && state.entries.isNotEmpty;
    if (!silent && !hasData) {
      emit(state.copyWith(phase: VaultPhase.loading, clearError: true));
    }
    try {
      final entries = await _load();
      if (isClosed) return;
      emit(
        state.copyWith(
          phase: VaultPhase.ready,
          entries: entries,
          clearError: true,
        ),
      );
    } on Exception {
      if (isClosed) return;
      emit(state.copyWith(phase: VaultPhase.error, error: 'VaultUnavailable'));
    }
  }

  void setFilter(VaultFilter filter) {
    if (state.filter == filter) return;
    emit(state.copyWith(filter: filter));
  }

  /// Persists an add/edit. The state is updated immediately (optimistically)
  /// so the vault renders the new/edited row with zero lag; the SQLite write
  /// — including AES sealing — runs in the background. If the write fails the
  /// row is rolled back to its previous value (or removed if it was new).
  Future<void> upsert(VaultEntry entry) async {
    final previous = await _optimisticUpsert(entry);
    if (isClosed) return;

    final id = entry.id;
    _pendingWrites.add(id);
    try {
      await _save(entry);
    } on Exception {
      if (isClosed) return;
      _rollbackUpsert(entry, previous);
    } finally {
      _pendingWrites.remove(id);
    }
  }

  /// Applies the optimistic upsert and returns the previously stored entry
  /// (null when [entry] is brand new) so a failed write can roll back.
  Future<VaultEntry?> _optimisticUpsert(VaultEntry entry) async {
    final entries = List<VaultEntry>.of(state.entries);
    final index = entries.indexWhere((e) => e.id == entry.id);
    final previous = index >= 0 ? entries[index] : null;
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: entries,
        clearError: true,
      ),
    );
    return previous;
  }

  /// Restores the previous value after a failed upsert (keeps new rows out if
  /// the insert never landed).
  void _rollbackUpsert(VaultEntry entry, VaultEntry? previous) {
    final entries = List<VaultEntry>.of(state.entries);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index < 0) return;
    if (previous != null) {
      entries[index] = previous;
    } else {
      entries.removeAt(index);
    }
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: entries,
        clearError: true,
      ),
    );
  }

  /// Persists a delete. The row is removed from the UI immediately; the DB
  /// delete runs in the background. On failure the row is restored.
  Future<void> remove(String id) async {
    final previous = _optimisticRemove(id);
    if (isClosed) return;

    _pendingWrites.add(id);
    try {
      await _delete(id);
      if (isClosed) return;
    } on Exception {
      if (isClosed) return;
      _rollbackRemove(previous);
    } finally {
      _pendingWrites.remove(id);
    }
  }

  /// Applies the optimistic removal and returns the removed entry (for rollback).
  VaultEntry? _optimisticRemove(String id) {
    final entries = List<VaultEntry>.of(state.entries);
    VaultEntry? removed;
    for (var i = 0; i < entries.length; i++) {
      if (entries[i].id == id) {
        removed = entries[i];
        break;
      }
    }
    if (removed == null) return null;
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: List<VaultEntry>.of(entries.where((e) => e.id != id)),
        clearError: true,
      ),
    );
    return removed;
  }

  /// Restores a row whose delete failed.
  void _rollbackRemove(VaultEntry? removed) {
    if (removed == null) return;
    final entries = List<VaultEntry>.of(state.entries);
    entries.add(removed);
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: entries,
        clearError: true,
      ),
    );
  }

  /// State-only upsert for flows that already persisted [entry] themselves
  /// (e.g. the editor saved through its own repository) — keeps the vault list
  /// in sync without re-writing the row or re-decrypting the set.
  void applyUpsert(VaultEntry entry) {
    final entries = List<VaultEntry>.of(state.entries);
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) {
      entries[index] = entry;
    } else {
      entries.add(entry);
    }
    entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: entries,
        clearError: true,
      ),
    );
  }

  /// State-only removal for flows that already deleted [id] from storage.
  void applyRemove(String id) {
    emit(
      state.copyWith(
        phase: VaultPhase.ready,
        entries: List<VaultEntry>.of(state.entries.where((e) => e.id != id)),
        clearError: true,
      ),
    );
  }
}
