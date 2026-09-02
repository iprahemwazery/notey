import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// The threshold within which a second back press is treated as a request
/// to exit the app. Two consecutive presses closer than this are required;
/// a longer gap is treated as a fresh first press.
const Duration exitConfirmationWindow = Duration(seconds: 2);

/// Shows a "Press back again to exit" confirmation and only exits the app
/// (or reports to [onExit]) when the user presses back twice within
/// [exitConfirmationWindow].
///
/// Used on the shell's root screen so a single accidental back press at the
/// root route doesn't kill the app. The first press surfaces a snackbar;
/// the second press within the window triggers [onExit] (default: the system
/// app exit via [SystemNavigator.pop]).
///
/// On desktop/web there is no system back navigation, so this widget
/// degrades gracefully (never claims the back handling) when
/// `Platform` back button isn't applicable.
class DoubleBackExitHandler extends StatefulWidget {
  const DoubleBackExitHandler({
    super.key,
    required this.child,
    this.onExit,
  });

  final Widget child;

  /// Called when the user confirms exit. Defaults to [SystemNavigator.pop],
  /// which is what the framework uses to exit Android apps.
  final Future<Object?> Function()? onExit;

  @override
  State<DoubleBackExitHandler> createState() => _DoubleBackExitHandlerState();
}

class _DoubleBackExitHandlerState extends State<DoubleBackExitHandler> {
  DateTime? _lastPressAt;
  Timer? _resetTimer;

  bool get _wantsHandleSystemBack =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  /// Returns true when the back press was handled (snackbar shown or exit
  /// triggered), and false when the framework should carry out the default
  /// back action instead.
  bool _handleBack() {
    final now = DateTime.now();
    final previous = _lastPressAt;
    final withinWindow =
        previous != null &&
        now.difference(previous) <= exitConfirmationWindow;

    // Second press within the window → confirm exit.
    if (withinWindow) {
      _resetTimer?.cancel();
      _lastPressAt = null;
      unawaited(
        (widget.onExit ?? () => SystemNavigator.pop())(),
      );
      return true;
    }

    // First press → show confirmation and arm the window.
    _lastPressAt = now;
    _resetTimer?.cancel();
    _resetTimer = Timer(exitConfirmationWindow, () {
      if (mounted) _lastPressAt = null;
    });
    GlassSnackbar.show(
      message: AppLocalizations.of(context).pressBackAgainToExit,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Only intercept system back on Android, where a back button exists.
    if (!_wantsHandleSystemBack) return widget.child;

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // `canPop` is always false, so this fires on every back press.
        if (!didPop) _handleBack();
      },
      child: widget.child,
    );
  }
}
