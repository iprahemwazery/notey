import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';


/// Light + dark Material 3 themes built on the flex_color_scheme engine.
abstract final class AppTheme {
  static const Color _primary = Color(0xFF2E6FDB);
  static const Color _secondary = Color(0xFF00A86B);
  static const Color _tertiary = Color(0xFF00A8B4);

  static final FlexSchemeColor _colors = FlexSchemeColor(
    primary: _primary,
    primaryContainer: const Color(0xFFD9E8FF),
    secondary: _secondary,
    secondaryContainer: const Color(0xFFC9F0DC),
    tertiary: _tertiary,
    tertiaryContainer: const Color(0xFFC1F0F2),
    appBarColor: const Color(0xFFF3F7FF),
    error: const Color(0xFFBA1A1A),
    errorContainer: const Color(0xFFFFDAD6),
  );

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// Brand gradient used on the lock screen and accents.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[_primary, _secondary, _tertiary],
  );

  /// Build a TextStyle without any shadows.
  static TextStyle _clean(TextStyle? s) {
    if (s == null) return const TextStyle();
    return s.copyWith(shadows: <Shadow>[]);
  }

  /// Build a clean TextTheme with all shadows stripped.
  static TextTheme _cleanTextTheme(TextTheme t) {
    return TextTheme(
      displayLarge: _clean(t.displayLarge),
      displayMedium: _clean(t.displayMedium),
      displaySmall: _clean(t.displaySmall),
      headlineLarge: _clean(t.headlineLarge),
      headlineMedium: _clean(t.headlineMedium),
      headlineSmall: _clean(t.headlineSmall),
      titleLarge: _clean(t.titleLarge),
      titleMedium: _clean(t.titleMedium),
      titleSmall: _clean(t.titleSmall),
      bodyLarge: _clean(t.bodyLarge),
      bodyMedium: _clean(t.bodyMedium),
      bodySmall: _clean(t.bodySmall),
      labelLarge: _clean(t.labelLarge),
      labelMedium: _clean(t.labelMedium),
      labelSmall: _clean(t.labelSmall),
    );
  }

  /// Strip shadows from a WidgetStateProperty.
  static WidgetStateProperty<TextStyle?>? _cleanWidgetStateTextStyle(
    WidgetStateProperty<TextStyle?>? prop,
  ) {
    if (prop == null) return null;
    return WidgetStateProperty.resolveWith((states) {
      final style = prop.resolve(states);
      return _clean(style);
    });
  }

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = FlexThemeData.light(
      colors: _colors,
      useMaterial3: true,
      fontFamily: AppConstants.fontFamily,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 25,
    );

    final darkBase = FlexThemeData.dark(
      colors: _colors,
      useMaterial3: true,
      fontFamily: AppConstants.fontFamily,
      // Dark keeps the scaffold noticeably darker than the cards so content
      // lifts off the background instead of flattening into it.
      surfaceMode: FlexSurfaceMode.highScaffoldLowSurfaces,
      blendLevel: 25,
    );

    final theme = isDark ? darkBase : base;
    final colorScheme = theme.colorScheme;

    final textTheme = _cleanTextTheme(
      theme.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );

    final primaryTextTheme = _cleanTextTheme(theme.primaryTextTheme);

    final rawChip = theme.chipTheme;
    final rawTabBar = theme.tabBarTheme;
    final rawListTile = theme.listTileTheme;
    final rawSnackBar = theme.snackBarTheme;

    final cleanedTheme = theme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF0E1116)
          : const Color(0xFFF4F7FB),
      appBarTheme: theme.appBarTheme.copyWith(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark
            ? const Color(0xFF0E1116)
            : const Color(0xFFF4F7FB),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        toolbarTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: .5)
            : Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 18.w,
          vertical: 16.h,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.r),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 1.6,
          ),
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: .7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 16.h,
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark
            ? colorScheme.surfaceContainerHigh
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.r),
        ),
        contentTextStyle: _clean(rawSnackBar.contentTextStyle),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
      ),
      chipTheme: rawChip.copyWith(
        labelStyle: _clean(rawChip.labelStyle),
      ),
      tabBarTheme: rawTabBar.copyWith(
        labelStyle: _clean(rawTabBar.labelStyle),
        unselectedLabelStyle: _clean(rawTabBar.unselectedLabelStyle),
      ),
      listTileTheme: rawListTile.copyWith(
        titleTextStyle: _clean(rawListTile.titleTextStyle),
        subtitleTextStyle: _clean(rawListTile.subtitleTextStyle),
      ),
      bottomSheetTheme: const BottomSheetThemeData(),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: _cleanWidgetStateTextStyle(
          theme.navigationBarTheme.labelTextStyle,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer.withValues(alpha: .5),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withValues(alpha: .32);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: .55),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(10.r),
        ),
        textStyle: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: .28),
        selectionHandleColor: colorScheme.primary,
      ),
      navigationRailTheme: NavigationRailThemeData(
        selectedLabelTextStyle: _clean(
          theme.navigationRailTheme.selectedLabelTextStyle,
        ),
        unselectedLabelTextStyle: _clean(
          theme.navigationRailTheme.unselectedLabelTextStyle,
        ),
      ),
      navigationDrawerTheme: const NavigationDrawerThemeData(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: _clean(theme.elevatedButtonTheme.style?.textStyle
              ?.resolve(const <WidgetState>{})),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: _clean(theme.textButtonTheme.style?.textStyle
              ?.resolve(const <WidgetState>{})),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: _clean(theme.outlinedButtonTheme.style?.textStyle
              ?.resolve(const <WidgetState>{})),
        ),
      ),
      bottomAppBarTheme: const BottomAppBarThemeData(),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: _clean(theme.dataTableTheme.headingTextStyle),
        dataTextStyle: _clean(theme.dataTableTheme.dataTextStyle),
      ),
      expansionTileTheme: const ExpansionTileThemeData(),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:
              CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows:
              FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:
              CupertinoPageTransitionsBuilder(),
        },
      ),
    );

    return cleanedTheme;
  }
}
