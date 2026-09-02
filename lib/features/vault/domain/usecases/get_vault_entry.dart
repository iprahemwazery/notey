import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';

/// Reads a single vault entry by id, `null` when missing or tampered.
class GetVaultEntry {
  GetVaultEntry(this._repository);

  final VaultRepository _repository;

  Future<VaultEntry?> call(String id) => _repository.get(id);
}
