import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/services/note_lock_service.dart';
import 'package:notey/features/notes/presentation/screens/note_view_screen.dart';

import 'helpers.dart';

void main() {
  setUp(() => setUpCommon());

  group('NoteViewScreen', () {
    testWidgets('displays note title and content',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(
        repo,
        title: 'عنوان الملاحظة',
        content: 'محتوى الملاحظة التفصيلي',
      );

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('عنوان الملاحظة'), findsOneWidget);
      expect(find.text('محتوى الملاحظة التفصيلي'), findsOneWidget);
    });

    testWidgets('shows created and modified labels',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('أُنشئت'), findsOneWidget);
      expect(find.text('آخر تعديل'), findsOneWidget);
    });

    testWidgets('shows "no details" for empty content',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo, content: '');

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا توجد تفاصيل'), findsOneWidget);
    });

    testWidgets('back button returns to previous screen',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo, title: 'عودة');

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('عودة'), findsOneWidget);

      // Default AppBar back arrow
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on placeholder — note title gone
      expect(find.text('عودة'), findsNothing);
    });

    testWidgets('share button is present',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('edit button navigates to editor',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(
        repo,
        title: 'قابل للتعديل',
        content: 'المحتوى',
      );

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'عنوان الملاحظة...'), findsOneWidget);
    });

    testWidgets('protected note shows lock panel',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo);
      final locked = await NoteLockService.lock(note, '123456');
      await repo.update(locked);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: locked, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('هذه الملاحظة محمية بكلمة سر'), findsOneWidget);
      expect(find.text('فتح الملاحظة'), findsOneWidget);
    });

    testWidgets('wrong password shows error',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(repo);
      final locked = await NoteLockService.lock(note, '123456');
      await repo.update(locked);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: locked, repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'كلمة السر'),
        '999999',
      );
      await tester.tap(find.text('فتح الملاحظة'));
      await tester.pump();
      await tester.runAsync(() =>
          Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pumpAndSettle();

      expect(find.text('كلمة السر غير صحيحة'), findsOneWidget);
    });

    testWidgets('correct password unlocks note',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(
        repo,
        title: 'سرية',
        content: 'محتوى سري',
      );
      final locked = await NoteLockService.lock(note, '123456');
      await repo.update(locked);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: locked, repository: repo)),
      );
      await tester.pumpAndSettle();

      // Content should not be visible while locked
      expect(find.text('محتوى سري'), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextField, 'كلمة السر'),
        '123456',
      );
      await tester.tap(find.text('فتح الملاحظة'));
      await tester.pump();
      await tester.runAsync(() =>
          Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.pumpAndSettle();

      expect(find.text('محتوى سري'), findsOneWidget);
    });

    testWidgets('note with checklist items renders check boxes',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(
        repo,
        content: '- [ ] مهمة أولى\n- [x] مهمة منجزة',
      );

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('مهمة أولى'), findsOneWidget);
      expect(find.text('مهمة منجزة'), findsOneWidget);
    });
  });
}
