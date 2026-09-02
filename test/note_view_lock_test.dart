import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/features/notes/presentation/screens/note_view_screen.dart';

import 'helpers.dart';

void main() {
  setUp(() => setUpCommon());

  group('NoteViewScreen lock state sync', () {
    testWidgets('setting a password locks the note, persists it, and shows '
        'the lock panel immediately', (WidgetTester tester) async {
      final repo = FakeRepository();
      final note = await createTestNote(
        repo,
        title: 'سري',
        content: 'محتوى سري',
      );
      expect(note.isLocked, isFalse);

      await tester.pumpWidget(
        buildTestApp(NoteViewScreen(note: note, repository: repo)),
      );
      await tester.pumpAndSettle();

      // Content visible while unlocked.
      expect(find.text('محتوى سري'), findsOneWidget);

      // Open the protection sheet and choose "set password".
      await tester.tap(find.byIcon(Icons.lock_open_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تعيين كلمة سر'));
      await tester.pumpAndSettle();

      // Enter + confirm the password, then press "تأمين".
      await tester.enterText(
        find.widgetWithText(TextField, 'كلمة السر').first,
        '123456',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'تأكيد كلمة السر').first,
        '123456',
      );
      await tester.tap(find.text('تأمين'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();

      // UI reflects the lock immediately.
      expect(find.text('هذه الملاحظة محمية بكلمة سر'), findsOneWidget);
      expect(find.text('فتح الملاحظة'), findsOneWidget);

      // DB reflects the lock and holds ciphertext.
      final persisted = await repo.getNote(note.id);
      expect(persisted?.isLocked, isTrue);
      expect(persisted?.title, isNot('سري'));
      expect(persisted?.content, isNot('محتوى سري'));

      // Let the GlassSnackbar's auto-dismiss timer elapse so the test teardown
      // doesn't trip the "Timer is still pending" invariant.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
