import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/services/note_lock_service.dart';
import 'package:notey/data/database/note_database.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';
import 'package:notey/features/notes/domain/entities/note.dart';

void main() {
  late NoteRepositoryImpl repository;
  late NoteDatabase database;

  setUp(() async {
    database = NoteDatabase(inMemory: true);
    repository = NoteRepositoryImpl(database: database);
  });

  tearDown(() => database.close());

  test('insert stamps created & updated timestamps automatically', () async {
    final note = Note.create(title: 'عنوان', content: 'محتوى');

    await repository.insert(note);

    expect(note.createdAt, isNotNull);
    expect(note.updatedAt, isNotNull);
    expect(note.updatedAt.difference(note.createdAt).inSeconds.abs(), lessThanOrEqualTo(1));
  });

  test('notes round-trip and come back newest-first', () async {
    await repository.insert(Note.create(title: 'الأولى', content: 'أ'));
    await repository.insert(Note.create(title: 'الثانية', content: 'ب'));

    final notes = await repository.getNotes();

    expect(notes.length, 2);
    expect(notes.first.title, 'الثانية');
    expect(notes[0].content, 'ب');
  });

  test('update refreshes updatedAt but keeps createdAt', () async {
    final original = Note.create(title: 'قبل التعديل', content: 'قديم');
    await repository.insert(original);

    await Future<void>.delayed(const Duration(milliseconds: 5));

    final updated = original.copyWith(
      title: 'بعد التعديل',
      content: 'جديد',
      updatedAt: DateTime.now(),
    );
    await repository.update(updated);

    final reloaded = await repository.getNote(original.id);

    expect(reloaded, isNotNull);
    expect(reloaded!.title, 'بعد التعديل');
    expect(reloaded.content, 'جديد');
    expect(reloaded.createdAt.millisecondsSinceEpoch, original.createdAt.millisecondsSinceEpoch);
    expect(reloaded.updatedAt.isAfter(original.createdAt), isTrue);
  });

  test('search filters by title and content', () async {
    await repository.insert(Note.create(title: 'مشتريات السوق', content: 'حليب وخبز'));
    await repository.insert(Note.create(title: 'مهام العمل', content: 'اجتماع السوق'));

    expect((await repository.getNotes(search: 'السوق')).length, 2);
    expect((await repository.getNotes(search: 'مشتريات')).length, 1);
    expect((await repository.getNotes(search: 'غير موجود')).length, 0);
  });

  test('pinned flag persists through save/load', () async {
    final note = Note.create(title: 'مثبتة', content: 'x', pinned: true);
    await repository.insert(note);

    final reloaded = await repository.getNote(note.id);

    expect(reloaded, isNotNull);
    expect(reloaded!.pinned, isTrue);
  });

  test('purge removes the note permanently', () async {
    final note = Note.create(title: 'لتحذف', content: 'x');
    await repository.insert(note);

    await repository.purge(note.id);

    expect(await repository.getNotes(), isEmpty);
    expect(await repository.getNote(note.id), isNull);
  });

  test('soft delete hides the note and restore brings it back', () async {
    final note = Note.create(title: 'محذوفة مؤقتًا', content: 'س');
    await repository.insert(note);

    await repository.softDelete(note.id);

    expect(await repository.getNotes(), isEmpty);
    final trashed = await repository.getDeletedNotes();
    expect(trashed.length, 1);
    expect(trashed.first.deletedAt, isNotNull);
    // getNote still finds it so the viewer/editor keep working.
    expect((await repository.getNote(note.id))!.deletedAt, isNotNull);

    await repository.restore(note.id);

    final restored = await repository.getNotes();
    expect(restored.length, 1);
    expect(restored.first.title, 'محذوفة مؤقتًا');
    expect(restored.first.deletedAt, isNull);
  });

  test('search ignores trashed notes', () async {
    final a = Note.create(title: 'مشتريات', content: 'حليب');
    final b = Note.create(title: 'أعمال', content: 'تقرير');
    await repository.insert(a);
    await repository.insert(b);
    await repository.softDelete(b.id);

    final hits = await repository.getNotes(search: 'تقرير');
    expect(hits, isEmpty);
    expect((await repository.getNotes(search: 'حليب')).length, 1);
  });

  test('search treats LIKE wildcards as literal characters', () async {
    await repository.insert(Note.create(title: 'خصم 100%', content: 'عرض'));
    await repository.insert(Note.create(title: 'snake_case هنا', content: 'عادي'));

    expect((await repository.getNotes(search: '100%')).length, 1);
    expect((await repository.getNotes(search: '10%0')).length, 0);
    expect((await repository.getNotes(search: '_case')).length, 1);
    expect((await repository.getNotes(search: 'xcasex')).length, 0);
  });

  test('searchNotes reports where the match happened', () async {
    await repository.insert(Note.create(title: 'عنوان مميز', content: 'نص عادي'));
    await repository.insert(Note.create(title: 'عنوان عادي', content: 'جملة خاصة بأمر'));

    final titleHits = await repository.searchNotes(search: 'مميز');
    expect(titleHits.length, 1);
    expect(titleHits.single.matchedInTitle, isTrue);

    final contentHits = await repository.searchNotes(search: 'خاصة');
    expect(contentHits.length, 1);
    expect(contentHits.single.matchedInContent, isTrue);
  });

  test('searchNotes finds text inside attached text files', () async {
    final dir = await Directory.systemTemp.createTemp('notey_search_');
    final file = File('${dir.path}/ملاحظات.txt');
    await file.writeAsString('قائمة جرافات الدقيق والقمح', flush: true);
    try {
      final note = Note.create(
        title: 'ملف مرفق',
        content: 'لا يوجد نص مطابق هنا',
        attachments: <String>[file.path],
      );
      await repository.insert(note);

      final hits = await repository.searchNotes(search: 'دقيق');
      expect(hits.length, 1);
      expect(hits.single.matchedInFile, isTrue);
      expect(hits.single.preview.toLowerCase(), contains('دقيق'));
      expect(hits.single.fileName, 'ملاحظات.txt');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('searchNotes never returns locked notes or leaks their ciphertext',
      () async {
    final note = Note.create(title: 'خادم سري', content: 'محتوى محمي سري');
    final locked = await NoteLockService.lock(note, '123456');
    await repository.insert(locked);

    expect((await repository.searchNotes(search: 'سري')), isEmpty);

    final hits = await repository.searchNotes(search: 'خادم');
    expect(hits, isEmpty);
  });

  test('batch insert/update writes every note in one transaction', () async {
    final a = Note.create(title: 'أ', content: '');
    final b = Note.create(title: 'ب', content: '');
    await repository.insertAll(<Note>[a, b]);
    expect((await repository.getNotes()).length, 2);

    await repository.updateAll(<Note>[
      a.copyWith(title: 'أ2'),
      b.copyWith(title: 'ب2'),
    ]);

    final notes = await repository.getNotes();
    expect(notes.map((n) => n.title), containsAll(<String>['أ2', 'ب2']));
  });

  test('emptyTrash purges only trashed notes and returns them', () async {
    final kept = Note.create(title: 'باقية', content: '');
    final gone1 = Note.create(title: 'رايحة ١', content: '');
    final gone2 = Note.create(title: 'رايحة ٢', content: '');
    await repository.insertAll(<Note>[kept, gone1, gone2]);
    await repository.softDeleteAll(<String>[gone1.id, gone2.id]);

    final purged = await repository.emptyTrash();

    expect(purged.length, 2);
    final left = await repository.getAllNotesIncludingDeleted();
    expect(left.length, 1);
    expect(left.single.title, 'باقية');
  });

  test('purgeExpired removes notes older than the retention window',
      () async {
    final old = Note.create(title: 'قديمة', content: '');
    final fresh = Note.create(title: 'جديدة', content: '');
    await repository.insertAll(<Note>[old, fresh]);
    final now = DateTime.now();
    await repository.softDelete(old.id,
        at: now.subtract(const Duration(days: 31)));
    await repository.softDelete(fresh.id, at: now);

    final expired =
        await repository.purgeExpired(const Duration(days: 30), now: now);

    expect(expired.single.title, 'قديمة');
    final remaining = await repository.getDeletedNotes();
    expect(remaining.single.title, 'جديدة');
  });

  test('tags and reminderAt survive a database roundtrip', () async {
    final note = Note.create(
      title: 'موسومة',
      content: '',
      tags: <String>['شغل', 'مهم'],
      reminderAt: DateTime.now().add(const Duration(hours: 2)),
    );
    await repository.insert(note);

    final loaded = await repository.getNote(note.id);
    expect(loaded, isNotNull);
    expect(loaded!.tags, <String>['شغل', 'مهم']);
    expect(loaded.reminderAt, isNotNull);

    final updated = loaded.copyWith(tags: <String>['شغل']);
    await repository.update(updated);
    final reloaded = await repository.getNote(note.id);
    expect(reloaded!.tags, <String>['شغل']);
  });
}
