import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notey/core/theme/app_theme.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => MaterialApp(theme: AppTheme.dark, home: child),
    );

void main() {
  testWidgets('AppTheme surfaces + text all follow dark mode', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox()));

    final dark = AppTheme.dark;
    final brightness = ThemeData.estimateBrightnessForColor;

    // Text targets are light in dark mode.
    expect(brightness(dark.colorScheme.onSurface), Brightness.light);
    expect(brightness(dark.colorScheme.onSurfaceVariant), Brightness.light);

    // Backgrounds are dark in dark mode.
    for (final surface in <Color?>[
      dark.scaffoldBackgroundColor,
      dark.canvasColor,
      dark.cardColor,
      dark.bottomSheetTheme.backgroundColor,
      dark.bottomSheetTheme.modalBackgroundColor,
      dark.navigationBarTheme.backgroundColor,
      dark.appBarTheme.backgroundColor,
    ]) {
      expect(
        surface,
        isNotNull,
        reason: 'surface should be configured',
      );
      expect(
        brightness(surface!),
        Brightness.dark,
        reason: 'surface $surface should be dark in dark mode',
      );
    }

    // Light mode flips everything.
    final light = AppTheme.light;
    expect(brightness(light.scaffoldBackgroundColor), Brightness.light);
    expect(brightness(light.colorScheme.onSurface), Brightness.dark);
  });
}
