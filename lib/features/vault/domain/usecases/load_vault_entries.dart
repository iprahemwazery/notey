import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';

/// Loads all decrypted vault entries, newest first.
class LoadVaultEntries {
  LoadVaultEntries(this._repository);

  final VaultRepository _repository;

  Future<List<VaultEntry>> call() => _repository.getAll();
}
