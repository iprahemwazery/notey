import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';

/// Lets the user pick a backup file and parse it, returning the recoverable
/// notes; `null` when the selection is cancelled.
class ImportBackup {
  ImportBackup(this._repository);

  final BackupRepository _repository;

  Future<List<Note>?> call() async {
    final path = await _repository.pickImportFile();
    if (path == null) return null;
    return _repository.parse(path);
  }
}
