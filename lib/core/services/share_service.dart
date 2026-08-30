import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Thin, test/desktop-safe wrapper around [SharePlus] for sharing decrypted
/// notes and exported attachments.
abstract final class ShareService {
  /// Shares plain text (e.g. a decrypted vault entry or note).
  static Future<bool> shareText(String text, {String? subject}) async {
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: subject),
      );
      return true;
    } on MissingPluginException {
      return false;
    } on Exception {
      return false;
    }
  }

  /// Shares one or more files by path.
  static Future<bool> shareFiles(List<String> paths) async {
    if (paths.isEmpty) return false;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[for (final p in paths) XFile(p)],
        ),
      );
      return true;
    } on MissingPluginException {
      return false;
    } on Exception {
      return false;
    }
  }
}