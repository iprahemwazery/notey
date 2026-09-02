import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:notey/core/services/backup_service.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/data/models/note_model.dart';

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getTemporaryPath() async => p.join(root, 'tmp');

  @override
  Future<String?> getApplicationDocumentsPath() async => p.join(root, 'docs');
}

void main() {
  late Directory root;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    root = await Directory.systemTemp.createTemp('notey_backup_test');
    await Directory(p.join(root.path, 'tmp')).create(recursive: true);
    await Directory(p.join(root.path, 'docs')).create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(root.path);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<Note> seedNoteWithFiles() async {
    final imagesDir = Directory(p.join(root.path, 'docs', 'note_images'))
      ..createSync(recursive: true);
    final filesDir = Directory(p.join(root.path, 'docs', 'note_files'))
      ..createSync(recursive: true);
    final img = File(p.join(imagesDir.path, 'img_1.png'))
      ..writeAsBytesSync(<int>[1, 2, 3, 255]);
    final doc = File(p.join(filesDir.path, 'doc_1.pdf'))
      ..writeAsBytesSync(<int>[37, 80, 68, 70]);
    return Note.create(
      title: 'ملاحظة',
      content: 'نص',
      attachments: <String>[img.path, doc.path],
    );
  }

  test('export embeds attachment bytes and rewrites paths to keys', () async {
    final note = await seedNoteWithFiles();
    final file = await BackupService.exportNotes(<Note>[note]);

    final decoded = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    expect(decoded['version'], 2);
    final embedded = decoded['files'] as Map<String, Object?>;
    expect(embedded.keys, containsAll(<String>['note_images/img_1.png', 'note_files/doc_1.pdf']));
    // The stored note map references keys, not device-specific absolute paths.
    final noteMap = (decoded['notes'] as List<Object?>).single as Map<String, Object?>;
    expect(noteMap['images'], contains('note_images/img_1.png'));
  });

  test('roundtrip restores files and remaps attachment paths', () async {
    final original = await seedNoteWithFiles();
    final backup = await BackupService.exportNotes(<Note>[original]);

    final restored = await BackupService.parseBackup(backup.path);
    expect(restored, hasLength(1));
    final note = restored.single;
    expect(note.id, isNot(original.id));
    expect(note.attachments, hasLength(2));

    for (final path in note.attachments) {
      expect(File(path).existsSync(), isTrue);
      expect(p.basename(path), anyOf('img_1.png', 'doc_1.pdf'));
      expect(path, startsWith(p.join(root.path, 'docs')));
    }
    final imgBytes =
        File(note.attachments.firstWhere((a) => a.endsWith('.png'))).readAsBytesSync();
    expect(imgBytes, <int>[1, 2, 3, 255]);
  });

  test('legacy v1 envelopes import without attachments', () async {
    final legacy = File(p.join(root.path, 'v1.json'))
      ..writeAsStringSync(jsonEncode(<String, Object?>{
        'app': 'notey',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'notes': <Object?>[
          NoteModel.toMap(Note.create(
            title: 'قديمة',
            content: '',
            attachments: <String>['/old/device/img.jpg'],
          )),
        ],
      }));

    final restored = await BackupService.parseBackup(legacy.path);
    expect(restored.single.attachments, isEmpty);
    expect(restored.single.deletedAt, isNull);
  });

  test('missing attachment files are dropped silently on export/import', () async {
    final note = Note.create(
      title: 'ت',
      content: '',
      attachments: <String>['/does/not/exist.png'],
    );
    final backup = await BackupService.exportNotes(<Note>[note]);
    final restored = await BackupService.parseBackup(backup.path);
    expect(restored.single.attachments, isEmpty);
  });
}
