import 'package:notey/features/vault/domain/entities/vault_entry.dart';

enum VaultPhase { initial, loading, ready, error }

/// Category filter chips for the vault: passwords, banking, documents,
/// audio and canvas sketches.
enum VaultFilter {
  all,
  passwords,
  banking,
  documents,
  audio,
  canvas;

  bool matches(VaultEntry entry) {
    return switch (this) {
      VaultFilter.all => true,
      VaultFilter.passwords => entry.category == VaultCategory.login,
      VaultFilter.banking =>
        entry.category == VaultCategory.creditCard ||
            entry.category == VaultCategory.bankAccount,
      VaultFilter.documents => entry.mediaType == VaultMediaType.document,
      VaultFilter.audio => entry.mediaType == VaultMediaType.audio,
      VaultFilter.canvas => entry.mediaType == VaultMediaType.drawing,
    };
  }
}

class VaultState {
  const VaultState({
    this.phase = VaultPhase.initial,
    this.entries = const <VaultEntry>[],
    this.filter = VaultFilter.all,
    this.error,
  });

  final VaultPhase phase;
  final List<VaultEntry> entries;
  final VaultFilter filter;
  final String? error;

  List<VaultEntry> get filteredEntries =>
      entries.where(filter.matches).toList();

  VaultState copyWith({
    VaultPhase? phase,
    List<VaultEntry>? entries,
    VaultFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return VaultState(
      phase: phase ?? this.phase,
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
