import 'dart:io';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:notey/core/constants/app_constants.dart';


/// Handles picking and persisting images attached to notes.
class ImageStore {
  ImageStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  final Random _random = Random();

  Future<XFile?> pickFromCamera() => _picker.pickImage(
    source: ImageSource.camera,
    imageQuality: 85,
    maxWidth: 1920,
  );

  Future<XFile?> pickFromGallery() => _picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1920,
  );

  /// Copies the picked image into the app's private folder and
  /// returns the absolute path to store in the database.
  Future<String> persist(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, AppConstants.imagesFolder));
    await imagesDir.create(recursive: true);

    final ext = _imageExtension(file);
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(0xFFFF).toRadixString(16)}$ext';
    final target = p.join(imagesDir.path, name);
    final saved = await File(file.path).copy(target);
    return saved.path;
  }

  /// Determines the correct file extension for an image [XFile].
  /// Checks the file name/path first, then falls back to MIME type, and
  /// finally defaults to `.jpg`.
  static String _imageExtension(XFile file) {
    var ext = p.extension(file.name).isNotEmpty
        ? p.extension(file.name)
        : p.extension(file.path);
    if (ext.isNotEmpty) return ext.toLowerCase();

    final mime = file.mimeType ?? '';
    if (mime == 'image/png') return '.png';
    if (mime == 'image/gif') return '.gif';
    if (mime == 'image/webp') return '.webp';
    if (mime == 'image/heic') return '.heic';
    if (mime == 'image/heif') return '.heif';
    return '.jpg';
  }

  /// Copies any picked document into the app's private files folder,
  /// preserving its original extension, and returns the absolute path.
  Future<String> persistDocument(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final filesDir = Directory(p.join(dir.path, AppConstants.filesFolder));
    await filesDir.create(recursive: true);

    var ext = p.extension(file.name).isNotEmpty
        ? p.extension(file.name)
        : p.extension(file.path);
    if (ext.isNotEmpty) ext = ext.toLowerCase();

    final name =
        '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(0xFFFF).toRadixString(16)}$ext';
    final target = p.join(filesDir.path, name);
    final saved = await File(file.path).copy(target);
    return saved.path;
  }

  /// Removes an image file from disk. Fails silently if missing.
  Future<void> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Ignore missing/unwritable files.
    }
  }

  /// Deletes unreferenced files inside the attachments folders (images and
  /// documents) — e.g. leftovers from an interrupted flow. Files younger than
  /// [minAge] are kept: they may belong to a pick still in progress.
  /// Returns how many files were removed.
  Future<int> sweep(
    Set<String> referencedPaths, {
    Duration minAge = const Duration(days: 1),
  }) async {
    var removed = 0;
    for (final folder in <String>[
      AppConstants.imagesFolder,
      AppConstants.filesFolder,
    ]) {
      removed += await _sweepFolder(folder, referencedPaths, minAge);
    }
    return removed;
  }

  Future<int> _sweepFolder(
    String folder,
    Set<String> referencedPaths,
    Duration minAge,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final target = Directory(p.join(dir.path, folder));
      if (!await target.exists()) return 0;

      final cutoff = DateTime.now().subtract(minAge);
      var removed = 0;
      await for (final entity in target.list()) {
        if (entity is! File || referencedPaths.contains(entity.path)) continue;
        final stat = await entity.stat();
        if (stat.modified.isAfter(cutoff)) continue;
        try {
          await entity.delete();
          removed++;
        } on FileSystemException {
          // Ignore unwritable files.
        }
      }
      return removed;
    } on Exception {
      return 0;
    }
  }
}
