import 'package:notey/features/vault/domain/repositories/vault_repository.dart';

/// Deletes the vault entry with [id].
class DeleteVaultEntry {
  DeleteVaultEntry(this._repository);

  final VaultRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
