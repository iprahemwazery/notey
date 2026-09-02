import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/data/models/note_model.dart';

import 'package:notey/core/constants/app_constants.dart';


/// Exports/imports a JSON backup of every note (active + trashed).
///
/// Envelope v2 embeds attachment binaries as base64 under `files`, keyed by
/// `<folder>/<fileName>` (e.g. `note_images/173...jpg`). Note attachment
/// paths are rewritten to those keys so an import on any device can restore
/// both texts and files. v1 envelopes (no embedded files) still import, but
/// their attachments cannot be restored.
///
/// [exportNotes] writes incrementally — each note and its attachment files
/// are serialized to disk one at a time, avoiding a large in-memory map.
abstract final class BackupService {
  static const String _envelopeApp = 'notey';
  static const int _envelopeVersion = 2;

  /// Writes all notes + their attachment files to a timestamped file in the
  /// temp directory and returns it (ready to be shared/saved by the caller).
  ///
  /// Uses incremental JSON serialization: each note is written as it is
  /// processed, and each attachment file is read, base64-encoded, and written
  /// immediately — never holding more than one file's bytes in memory.
  static Future<File> exportNotes(List<Note> notes) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    IOSink? sink;
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp =
        '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
    final file = File(p.join(dir.path, 'notey_backup_$stamp.json'));

    sink = file.openWrite();

    try {
    // Track which files have already been embedded (by key).
    final writtenFiles = <String>{};

    // Write envelope header.
    sink.write('{\n');
    sink.write('  "app": "$_envelopeApp",\n');
    sink.write('  "version": $_envelopeVersion,\n');
    sink.write('  "exportedAt": "${now.toIso8601String()}",\n');

    // --- Notes array (incremental) ---
    sink.write('  "notes": [\n');
    for (int ni = 0; ni < notes.length; ni++) {
      final note = notes[ni];
      final keys = <String>[];
      for (final path in note.attachments) {
        final f = File(path);
        if (!await f.exists()) continue;
        final folder = p.basename(p.dirname(path));
        final key = '$folder/${p.basename(path)}';
        keys.add(key);
      }
      final noteMap = NoteModel.toMap(note.copyWith(attachments: keys));
      final encoded = const JsonEncoder.withIndent('    ').convert(noteMap);
      sink.write(encoded);
      if (ni < notes.length - 1) sink.write(',');
      sink.write('\n');
    }
    sink.write('  ],\n');

    // --- Files map (incremental — one file at a time) ---
    sink.write('  "files": {\n');
    bool firstFile = true;
    for (final note in notes) {
      for (final path in note.attachments) {
        final f = File(path);
        if (!await f.exists()) continue;
        final folder = p.basename(p.dirname(path));
        final key = '$folder/${p.basename(path)}';
        if (writtenFiles.contains(key)) continue;
        writtenFiles.add(key);

        // Read file bytes and encode — only ONE file in memory at a time.
        final bytes = await f.readAsBytes();
        final b64 = base64Encode(bytes);

        if (!firstFile) sink.write(',\n');
        firstFile = false;
        // Escape the key for JSON.
        final escapedKey = key.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
        sink.write('    "$escapedKey": "$b64"');
      }
    }
    sink.write('\n  }\n');
    sink.write('}\n');

    await sink.flush();
    await sink.close();
    sink = null;
    return file;
    } on Exception {
      await sink?.flush();
      await sink?.close();
      rethrow;
    }
  }

  /// Parses a backup file, restores embedded attachment files into the app's
  /// private folders, and returns the notes with fresh ids and absolute
  /// attachment paths pointing at the restored copies.
  /// Throws [FormatException] when the file is not a Notey backup.
  static Future<List<Note>> parseBackup(String filePath) async {
    final raw = await File(filePath).readAsString();
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('invalid-json');
    }
    if (decoded is! Map<String, Object?> ||
        decoded['app'] != _envelopeApp ||
        decoded['notes'] is! List<Object?>) {
      throw const FormatException('bad-envelope');
    }

    // Restore embedded binaries (v2+). Missing/corrupt entries are skipped.
    final keyToPath = <String, String>{};
    final embedded = decoded['files'];
    if (embedded is Map<String, Object?> && embedded.isNotEmpty) {
      final root = await getApplicationDocumentsDirectory();
      for (final entry in embedded.entries) {
        final key = entry.key;
        final parts = p.split(key);
        if (parts.length != 2 ||
            !<String>[
              AppConstants.imagesFolder,
              AppConstants.filesFolder,
            ].contains(parts.first)) {
          continue;
        }
        try {
          final raw = entry.value;
          if (raw is! String) continue;
          final bytes = base64Decode(raw);
          final dir = Directory(p.join(root.path, parts.first));
          await dir.create(recursive: true);
          final target = p.join(dir.path, parts.last);
          await File(target).writeAsBytes(bytes, flush: true);
          keyToPath[key] = target;
        } on Exception {
          continue;
        }
      }
    }

    final list = decoded['notes'] as List<Object?>;
    final notes = <Note>[];
    for (final item in list) {
      if (item is! Map<String, Object?>) continue;
      try {
        final note = NoteModel.fromMap(item);
        final restored = <String>[
          for (final key in note.attachments)
            if (keyToPath.containsKey(key)) keyToPath[key]!,
        ];
        notes.add(note.copyWith(
          id: Note.newId(),
          attachments: restored,
          deletedAt: null,
        ));
      } on Exception {
        continue;
      }
    }
    return notes;
  }
}
