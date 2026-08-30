import 'package:flutter/foundation.dart';

/// Global error reporter: mirrors every Flutter/build/async/platform error to
/// the console `flutter run` prints to, with an origin tag and a stack trace.
///
/// Identical repeated errors are collapsed (marked "↻ repeated") so a single
/// recurring assertion (e.g. flex_color_scheme's negative blur radius) is
/// still reported without flooding the terminal with the same wall of text.
abstract final class ErrorLogger {
  static final Set<String> _seen = <String>{};
  static const int _maxSeen = 256;
  static const int _maxStackLines = 22;

  static void _log(String tag, String message, StackTrace? stack) {
    final String key = '$tag|$message';
    final bool first = _seen.add(key);
    if (_seen.length > _maxSeen) _seen.clear();

    debugPrint('$tag ▶ $message${first ? '' : '  ↻ repeated'}');
    if (first && stack != null) {
      final List<String> lines = stack.toString().split('\n');
      debugPrint(lines.take(_maxStackLines).join('\n'));
    }
  }

  /// Flutter framework/build/layout/render errors (`FlutterError.onError`).
  static void flutterError(FlutterErrorDetails details) {
    _log('[flutter]', details.exceptionAsString(), details.stack);
  }

  /// Uncaught asynchronous errors from the root zone (`runZonedGuarded`).
  static void asyncError(Object error, StackTrace? stack) {
    _log('[async]', error.toString(), stack);
  }

  /// Dart isolate/`PlatformDispatcher` errors.
  static void platformError(Object error, StackTrace? stack) {
    _log('[platform]', error.toString(), stack);
  }

  /// Manual logs from services (always visible in `flutter run`).
  static void log(String message) => debugPrint('[app] $message');
}