import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// Picks a representative Material icon for an attachment path.
IconData attachmentIcon(String path) {
  switch (p.extension(path).toLowerCase()) {
    case '.pdf':
      return Icons.picture_as_pdf_rounded;
    case '.zip':
    case '.rar':
    case '.7z':
      return Icons.folder_zip_rounded;
    case '.mp3':
    case '.wav':
    case '.m4a':
    case '.ogg':
      return Icons.audio_file_rounded;
    case '.mp4':
    case '.mov':
    case '.avi':
    case '.mkv':
      return Icons.video_file_rounded;
    case '.doc':
    case '.docx':
    case '.odt':
    case '.rtf':
      return Icons.description_rounded;
    case '.xls':
    case '.xlsx':
    case '.ods':
    case '.csv':
      return Icons.table_chart_rounded;
    case '.ppt':
    case '.pptx':
    case '.odp':
      return Icons.slideshow_rounded;
    case '.txt':
    case '.md':
      return Icons.article_rounded;
    case '.apk':
      return Icons.android_rounded;
    default:
      return Icons.insert_drive_file_rounded;
  }
}
