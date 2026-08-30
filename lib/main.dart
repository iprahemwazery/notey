import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/services/error_logger.dart';
import 'core/services/locale_controller.dart';
import 'core/services/reminder_service.dart';
import 'core/services/share_receiver.dart';
import 'core/theme/theme_controller.dart';

void main() {
  // Isolate-level errors (e.g. platform channel failures) — report and keep
  // the app alive instead of silently terminating.
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLogger.platformError(error, stack);
    return true;
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Every Flutter/framework/build/layout/render error is mirrored to the
      // `flutter run` console with its stack (deduped repeats). The old
      // flex_color_scheme blur-radius suppression is intentionally gone: that
      // assertion is far less spammy than a launch always ending in the void.
      FlutterError.onError = ErrorLogger.flutterError;

      // Boot trace — every stage is time-stamped so a stuck/frozen launch on
      // device shows up immediately in `flutter run` output.
      final t0 = DateTime.now();
      void bootLog(String stage) {
        if (!kDebugMode) return;
        debugPrint(
          '[boot] +${DateTime.now().difference(t0).inMilliseconds}ms $stage',
        );
      }

      bootLog('binding ready');

      // Time-bounded init: runApp must ALWAYS happen even if a cheap pref read
      // never resolves. Each init gets a hard 3s budget, then we move on.
      int remaining() => 3000 - DateTime.now().difference(t0).inMilliseconds;

      try {
        await ThemeController.instance.init().timeout(
          Duration(milliseconds: remaining()),
        );
      } on Exception catch (e) {
        ErrorLogger.log('ThemeController init failed: $e');
      }
      bootLog('theme ready');

      try {
        await LocaleController.instance.init().timeout(
          Duration(milliseconds: remaining()),
        );
      } on Exception catch (e) {
        ErrorLogger.log('LocaleController init failed: $e');
      }
      bootLog('locale ready');

      // These two are non-critical — fire-and-forget is fine.
      unawaited(
        ReminderService.init().catchError((e) {
          ErrorLogger.log('ReminderService init failed: $e');
        }),
      );
      unawaited(
        ShareReceiver.init().catchError((e) {
          ErrorLogger.log('ShareReceiver init failed: $e');
        }),
      );

      runApp(const NoteyApp());
      bootLog('runApp dispatched');
    },
    (error, stack) {
      ErrorLogger.asyncError(error, stack);
    },
  );
}
