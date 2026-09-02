import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:notey/features/shell/presentation/widgets/double_back_exit_handler.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

const _exitMessage = 'Press back again to exit';

Future<void> _sendBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump();
}

/// Closes any open snackbar and advances time so no display timer is left
/// pending when the test ends.
Future<void> _flush(WidgetTester tester) async {
  Get.closeAllSnackbars();
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Widget _harness({Future<Object?> Function()? onExit}) {
  return ScreenUtilInit(
    designSize: const Size(360, 690),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => GetMaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(
        builder: (context) => DoubleBackExitHandler(
          onExit: onExit ??
              () async {
                throw StateError('default exit called');
              },
          child: const Scaffold(body: Text('root')),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('single back press shows snackbar and does not exit',
      (WidgetTester tester) async {
    var exits = 0;
    await tester.pumpWidget(
      _harness(
        onExit: () async {
          exits++;
          return null;
        },
      ),
    );

    await _sendBack(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(exits, 0);
    expect(find.text(_exitMessage), findsOneWidget);

    await _flush(tester);
  });

  testWidgets('two back presses within window exit the app',
      (WidgetTester tester) async {
    var exits = 0;
    await tester.pumpWidget(
      _harness(
        onExit: () async {
          exits++;
          return null;
        },
      ),
    );

    await _flush(tester);
    await _sendBack(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await _sendBack(tester);

    expect(exits, 1);

    await _flush(tester);
  });

  testWidgets('back press after the window is treated as a fresh first press',
      (WidgetTester tester) async {
    var exits = 0;
    await tester.pumpWidget(
      _harness(
        onExit: () async {
          exits++;
          return null;
        },
      ),
    );

    await _sendBack(tester);
    await tester.pump(const Duration(seconds: 3));
    await _sendBack(tester);

    expect(exits, 0);

    await _flush(tester);
  });
}
