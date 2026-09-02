import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/app_reset_service.dart';
import 'package:notey/core/services/backup_service.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';

/// Concrete [BackupRepository] backed by the shared backup/reset services and
/// the platform file/share/version primitives.
class BackupRepositoryImpl implements BackupRepository {
  BackupRepositoryImpl({AppLockController? lockController})
    : _lockController = lockController;

  final AppLockController? _lockController;

  @override
  Future<String> export(List<Note> notes) async {
    final file = await BackupService.exportNotes(notes);
    return file.path;
  }

  @override
  Future<String?> pickImportFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    return files.isEmpty ? null : files.single.path;
  }

  @override
  Future<List<Note>> parse(String filePath) =>
      BackupService.parseBackup(filePath);

  @override
  Future<void> share(String filePath) async {
    await SharePlus.instance.share(
      ShareParams(files: <XFile>[XFile(filePath)]),
    );
  }

  @override
  Future<String> appVersion() async {
    final info = await PackageInfo.fromPlatform();
    return 'v${info.version}';
  }

  @override
  Future<void> wipeAllData() async {
    final controller = _lockController ?? AppLockController();
    await AppResetService.wipeAll(controller);
  }
}
