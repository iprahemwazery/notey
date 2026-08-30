import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:notey/features/notes/model/note.dart';


/// Generates export files for a single note in multiple formats.
abstract final class ExportService {
  /// Exports [note] as a Markdown `.md` file and returns it.
  static Future<File> exportMarkdown(Note note) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = _safeFilename(note.title);
    final file = File(p.join(dir.path, '$safeTitle.md'));

    final buf = StringBuffer();
    if (note.title.isNotEmpty) {
      buf.writeln('# ${note.title}');
      buf.writeln();
    }
    if (note.tags.isNotEmpty) {
      buf.writeln('**Tags:** ${note.tags.join(', ')}');
      buf.writeln();
    }
    if (note.folder.isNotEmpty) {
      buf.writeln('**Folder:** ${note.folder}');
      buf.writeln();
    }
    buf.writeln('---');
    buf.writeln();
    buf.writeln(note.content);
    buf.writeln();
    buf.writeln('---');
    buf.writeln('*Exported from Notey*');

    await file.writeAsString(buf.toString(), flush: true);
    return file;
  }

  /// Exports [note] as a PDF file and returns it.
  static Future<File> exportPdf(Note note) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = _safeFilename(note.title);
    final file = File(p.join(dir.path, '$safeTitle.pdf'));

    final pdf = pw.Document();
    final font = pw.Font.helvetica();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => <pw.Widget>[
          if (note.title.isNotEmpty)
            pw.Header(
              level: 0,
              child: pw.Text(
                note.title,
                style: pw.TextStyle(
                  font: font,
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          if (note.tags.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'Tags: ${note.tags.join(', ')}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          if (note.folder.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                'Folder: ${note.folder}',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            note.content.isEmpty ? 'No details' : note.content,
            style: pw.TextStyle(font: font, fontSize: 12, lineSpacing: 6),
          ),
          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.Text(
            'Exported from Notey',
            style: pw.TextStyle(
              font: font,
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );

    await file.writeAsBytes(await pdf.save(), flush: true);
    return file;
  }

  static String _safeFilename(String title) {
    final trimmed = title.trim().isEmpty ? 'untitled' : title.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
