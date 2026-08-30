import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/data/database/note_database.dart';

import 'app_lock_controller.dart';

/// Erases every trace of app data: database, attachment files,
/// preferences and lock configuration. Used by the "forgot PIN"
/// recovery path where the only option is a full reset.
abstract final class AppResetService {
  /// [documentsPath] is injectable for tests.
  static Future<void> wipeAll(
    AppLockController controller, {
    Future<String> Function()? documentsPath,
  }) async {
    // Close any open connection before removing the files underneath it.
    try {
      await NoteDatabase.instance.close();
    } on Exception {
      // Ignore — nothing open.
    }

    try {
      final String root;
      if (documentsPath != null) {
        root = await documentsPath();
      } else {
        root = (await getApplicationDocumentsDirectory()).path;
      }
      for (final name in <String>[
        AppConstants.dbName,
        '${AppConstants.dbName}-wal',
        '${AppConstants.dbName}-shm',
        AppConstants.imagesFolder,
        AppConstants.filesFolder,
      ]) {
        // Deliberately synchronous: the wipe happens once, on a screen that
        // is about to be torn down anyway, and sync IO keeps it race-free
        // against any code that might recreate the folders mid-delete.
        final target = FileSystemEntity.typeSync(p.join(root, name));
        if (target == FileSystemEntityType.directory) {
          Directory(p.join(root, name)).deleteSync(recursive: true);
        } else if (target == FileSystemEntityType.file) {
          File(p.join(root, name)).deleteSync();
        }
      }
    } on Exception {
      // Best effort — never block the reset on file cleanup.
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } on Exception {
      // Ignore.
    }

    // Clears the stored PIN hash and flips the controller back to
    // "not configured", which routes the UI to first-run setup.
    await controller.reset();
  }
}
