import 'dart:io';

import 'package:path/path.dart' as p;

/// Pure-Dart classification helpers for note attachments (file paths).
/// UI-facing icon mapping lives in `file_icons.dart`.
abstract final class AttachmentUtils {
  static const Set<String> _imageExtensions = <String>{
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.heic',
  };

  /// Whether the attachment at [path] renders as an image thumbnail.
  static bool isImage(String path) =>
      _imageExtensions.contains(p.extension(path).toLowerCase());

  /// Human-readable file name of an attachment path.
  static String fileName(String path) => p.basename(path);

  /// Whether [path] exists as a readable file on disk.
  static Future<bool> exists(String path) async => File(path).exists();
}
