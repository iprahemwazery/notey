import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Opens attachment files with the device's native viewer (ACTION_VIEW):
/// PDFs in a reader, videos in a player, and so on.
abstract final class FileOpenerService {
  static const MethodChannel _channel = MethodChannel('notey/device');

  /// Returns false when the file is missing or no installed app can open it.
  static Future<bool> open(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return false;

      final ok = await _channel.invokeMethod<bool>(
        'openFile',
        <String, String>{'path': path},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on Exception {
      return false;
    }
  }

  /// Returns the file extension (lowercase, without dot) or empty string.
  static String extensionOf(String path) =>
      p.extension(path).toLowerCase().replaceFirst('.', '');

  /// Whether the file is a PDF by extension.
  static bool isPdf(String path) => extensionOf(path) == 'pdf';
}
