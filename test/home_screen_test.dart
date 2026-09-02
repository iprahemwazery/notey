import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notey/features/notes/presentation/screens/home_screen.dart';

import 'helpers.dart';

Finder _inHome(Finder matching) =>
    find.descendant(of: find.byType(HomeScreen), matching: matching);

void main() {
  setUp(() => setUpCommon());

  group('HomeScreen', () {
    testWidgets('shows empty state when there are no notes',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد ملاحظات بعد'), findsOneWidget);
      expect(find.text('اضغط زر "ملاحظة جديدة" للبدء'), findsOneWidget);
    });

    testWidgets('FAB shows new note button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('ملاحظة جديدة'), findsOneWidget);
    });

    testWidgets('tapping FAB navigates to editor',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ملاحظة جديدة'));
      await tester.pumpAndSettle();

      expect(find.text('ملاحظة جديدة'), findsWidgets);
      expect(
        find.widgetWithText(TextField, 'عنوان الملاحظة...'),
        findsOneWidget,
      );
    });

    testWidgets('displays inserted notes with title and content',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'ملاحظة أولى', content: 'محتوى أول');
      await createTestNote(repo, title: 'ملاحظة ثانية', content: 'محتوى ثاني');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('ملاحظة أولى'), findsOneWidget);
      expect(find.text('ملاحظة ثانية'), findsOneWidget);
    });

    testWidgets('notes count updates when notes exist',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'أ');
      await createTestNote(repo, title: 'ب');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('ملاحظتان'), findsOneWidget);
    });

    testWidgets('search field filters notes by title',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'قائمة تسوق');
      await createTestNote(repo, title: 'أفكار عمل');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
        'تسوق',
      );
      // Wait for search debounce (250ms) + UI settle
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('قائمة تسوق', findRichText: true), findsOneWidget);
      expect(find.text('أفكار عمل'), findsNothing);
    });

    testWidgets('search field filters notes by content',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'ملاحظة', content: 'تفاصيل مهمة جدًا');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
        'مهمة',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('ملاحظة', findRichText: true), findsOneWidget);
    });

    testWidgets('clear search restores all notes',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'أ');
      await createTestNote(repo, title: 'ب');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
        'أ',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('ب'), findsNothing);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.text('أ'), findsOneWidget);
      expect(find.text('ب'), findsOneWidget);
    });

    testWidgets('search history appears, re-runs and can be removed',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'مشتريات', content: 'حليب وخبز');
      await createTestNote(repo, title: 'أعمال', content: 'تقرير');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // First search records the term.
      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
        'مشتر',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('مشتريات', findRichText: true), findsOneWidget);

      // Clear it: keyboard unfocused, results gone.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Focusing the field reveals the history panel.
      await tester.tap(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
      );
      await tester.pumpAndSettle();
      expect(find.text('عمليات البحث الأخيرة'), findsOneWidget);
      expect(find.text('مشتر'), findsOneWidget);

      // Tapping the chip re-runs the search.
      await tester.tap(find.text('مشتر'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('مشتريات', findRichText: true), findsOneWidget);

      // Clear again and refocus to reveal history.
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
      );
      await tester.pumpAndSettle();
      expect(find.text('مشتر'), findsOneWidget);

      // X on the chip removes it from history (query is empty, so the only
      // X visible is the chip's delete icon).
      await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('مشتر'), findsNothing);
      expect(find.text('عمليات البحث الأخيرة'), findsNothing);
    });

    testWidgets('tapping outside the search field keeps results',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'قائمة تسوق');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'ابحث في ملاحظاتك...'),
        'تسوق',
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('قائمة تسوق', findRichText: true), findsOneWidget);

      // Tap somewhere neutral (the header area) — results must stay.
      await tester.tapAt(const Offset(20, 40));
      await tester.pumpAndSettle();
      expect(find.text('قائمة تسوق', findRichText: true), findsOneWidget);
      expect(find.text('عمليات البحث الأخيرة'), findsNothing);
    });

    testWidgets('tapping sort icon shows sort options',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.sort_rounded));
      await tester.pumpAndSettle();

      expect(find.text('الأحدث أولًا'), findsOneWidget);
      expect(find.text('الأقدم أولًا'), findsOneWidget);
      expect(find.text('حسب اللون'), findsOneWidget);
    });

    testWidgets('pinned note shows pin icon',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'مثبّتة', pinned: true);

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
    });

    testWidgets('settings tile opens settings screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(_inHome(find.byIcon(Icons.settings_outlined)));
      await tester.pumpAndSettle();

      expect(find.text('الإعدادات'), findsWidgets);
    });

    testWidgets('trash icon is visible in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(_inHome(find.byIcon(Icons.delete_outline_rounded)), findsOneWidget);
    });

    testWidgets('no notes shows single note count',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(FakeRepository()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('ابدأ بكتابة أول ملاحظة'), findsOneWidget);
    });

    testWidgets('long press on note card shows selection bar',
        (WidgetTester tester) async {
      final repo = FakeRepository();
      await createTestNote(repo, title: 'ملاحظة');

      await tester.pumpWidget(buildApp(repo));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.longPress(find.text('ملاحظة'));
      await tester.pumpAndSettle();

      // Selection bar appears at the bottom with palette, pin, delete icons
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_rounded), findsOneWidget);
      expect(_inHome(find.byIcon(Icons.delete_outline_rounded)), findsOneWidget);
    });
  });
}
