import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/data/repositories/secure_vault_repository.dart';

import 'package:notey/features/vault/model/vault_entry.dart';

import 'vault_state.dart';

/// Drives the digital vault: loads decrypted entries off the repository,
/// filters them across the category chips and persists add/edit/delete.
class VaultCubit extends Cubit<VaultState> {
  VaultCubit(this._repository) : super(const VaultState());

  final SecureVaultRepository _repository;

  /// Loads vault entries. A full-screen loading state is only shown for the
  /// initial empty-load or when explicitly requested; regular refreshes stay
  /// silent so the vault stays smooth while navigating in and out of entries.
  Future<void> load({bool silent = false}) async {
    final hasData = state.phase == VaultPhase.ready && state.entries.isNotEmpty;
    if (!silent && !hasData) {
      emit(state.copyWith(phase: VaultPhase.loading, clearError: true));
    }
    try {
      final entries = await _repository.getAll();
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

  Future<void> upsert(VaultEntry entry) async {
    await _repository.upsert(entry);
    await load(silent: true);
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    await load(silent: true);
  }
}
