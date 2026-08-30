import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notey/core/utils/markdown.dart';

void main() {
  Future<Finder> pump(WidgetTester tester, String data) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(home: Scaffold(body: MarkdownText(data: data))),
        ),
      ),
    );
    return find.byType(MarkdownText);
  }

  testWidgets('renders plain text as a single paragraph', (tester) async {
    final md = await pump(tester, 'سطر عادي');
    expect(md, findsOneWidget);
    expect(find.text('سطر عادي'), findsOneWidget);
  });

  testWidgets('renders headings bullets checkboxes and rules', (tester) async {
    await pump(
      tester,
      '# عنوان\n\n- عنصر\n- [ ] مهمة\n- [x] منجزة\n---\n**عريض** و *مائل* و `كود`',
    );
    expect(find.text('عنوان'), findsOneWidget);
    expect(find.text('عنصر'), findsOneWidget);
    expect(find.text('مهمة'), findsOneWidget);
    expect(find.text('منجزة'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outline_blank_rounded), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && w.textSpan?.toPlainText().contains('عريض') == true,
      ),
      findsOneWidget,
    );
  });
}
