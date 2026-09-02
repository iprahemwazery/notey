import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';

/// Exports [notes] to a shareable backup file and shares it via the system
/// share sheet.
class ExportBackup {
  ExportBackup(this._repository);

  final BackupRepository _repository;

  Future<void> call(List<Note> notes) async {
    final path = await _repository.export(notes);
    await _repository.share(path);
  }
}
