import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';

/// Persists an add/edit of a vault [entry] (sealed before storage).
class SaveVaultEntry {
  SaveVaultEntry(this._repository);

  final VaultRepository _repository;

  Future<void> call(VaultEntry entry) => _repository.upsert(entry);
}
