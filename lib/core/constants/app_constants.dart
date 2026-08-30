import 'package:flutter/material.dart';

/// Central place for app-wide constants.
abstract final class AppConstants {
  static const String appName = 'Notey';

  static const String dbName = 'notey.db';
  static const int dbVersion = 8;
  static const String imagesFolder = 'note_images';

  /// Private folder for non-image attachments (pdf, docx, zip, ...).
  static const String filesFolder = 'note_files';

  /// At-rest encrypted vault attachment files (`.enc`).
  static const String vaultFolder = 'vault_files';

  static const String fontFamily = 'Cairo';

  /// Vibrant note backgrounds (light tints + deep shades).
  /// Text color is picked automatically per background — see ColorUtils.
  static const List<Color> noteColors = <Color>[
    Color(0xFFFFF8E1), // أصفر فاتح
    Color(0xFFE8F5E9), // أخضر فاتح
    Color(0xFFE3F2FD), // أزرق فاتح
    Color(0xFFFFEBEE), // وردي فاتح
    Color(0xFFF3E5F5), // بنفسجي فاتح
    Color(0xFFFFF3E0), // برتقالي فاتح
    Color(0xFF42A5F5), // أزرق
    Color(0xFF66BB6A), // أخضر
    Color(0xFF26A69A), // تركواز
    Color(0xFFAB47BC), // بنفسجي غامق
    Color(0xFFEF5350), // مرجاني
    Color(0xFF5C6BC0), // نيلي
  ];
}
