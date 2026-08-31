import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notey/core/theme/app_theme.dart';

void main() {
  testWidgets('theme text colors', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) => const MaterialApp(home: SizedBox()),
      ),
    );
    final light = AppTheme.light;
    final dark = AppTheme.dark;
    // ignore: avoid_print
    print('LIGHT onSurface=${light.colorScheme.onSurface} '
        'surface=${light.colorScheme.surface} '
        'onSurfaceVariant=${light.colorScheme.onSurfaceVariant} '
        'bright=${light.brightness}');
    // ignore: avoid_print
    print('DARK  onSurface=${dark.colorScheme.onSurface} '
        'surface=${dark.colorScheme.surface} '
        'onSurfaceVariant=${dark.colorScheme.onSurfaceVariant} '
        'bright=${dark.brightness}');
    // ignore: avoid_print
    print('LIGHT chip.label=${light.chipTheme.labelStyle?.color} '
        'fill=${light.chipTheme.backgroundColor}');
    // ignore: avoid_print
    print('DARK chip.label=${dark.chipTheme.labelStyle?.color} '
        'fill=${dark.chipTheme.backgroundColor}');
    // ignore: avoid_print
    print('LIGHT bodyMedium=${light.textTheme.bodyMedium?.color} '
        'titleSmall=${light.textTheme.titleSmall?.color}');
    // ignore: avoid_print
    print('DARK bodyMedium=${dark.textTheme.bodyMedium?.color} '
        'titleSmall=${dark.textTheme.titleSmall?.color}');
    // ignore: avoid_print
    print('LIGHT listTile.title=${light.listTileTheme.titleTextStyle?.color} '
        'sub=${light.listTileTheme.subtitleTextStyle?.color}');
    // ignore: avoid_print
    print('DARK listTile.title=${dark.listTileTheme.titleTextStyle?.color} '
        'sub=${dark.listTileTheme.subtitleTextStyle?.color}');
  });
}