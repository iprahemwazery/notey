import 'dart:async';

import 'package:flutter/material.dart';

import 'package:notey/app.dart' show noteyNavigatorKey;

/// Route-independent, theme-aware toast/undo banner.
///
/// Renders into the root [Overlay] (via [noteyNavigatorKey]) instead of a
/// per-screen [ScaffoldMessenger], so the banner floats above every route,
/// survives route transitions and matches the active Material theme exactly —
/// no white flash, no fixed colors, no missed snackbars when a Scaffold is
/// mid-transition.
class GlobalSnackBar {
  GlobalSnackBar._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Shows a sticky toast. [actionLabel]/[onAction] create an optional action
  /// button (e.g. `undo`); the banner auto-dismisses after [duration].
  static void show({
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    hide();
    final overlay = noteyNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlobalSnackBarView(
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) _entry = null;
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  /// Removes the current banner (if any) immediately.
  static void hide() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    entry?.remove();
  }
}

class _GlobalSnackBarView extends StatefulWidget {
  const _GlobalSnackBarView({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_GlobalSnackBarView> createState() => _GlobalSnackBarViewState();
}

class _GlobalSnackBarViewState extends State<_GlobalSnackBarView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    _timer?.cancel();
    _timer = null;
    try {
      await _controller.reverse();
    } on Object {
      // The entry may already have been removed by a newer banner.
    }
    widget.onDismissed();
  }

  void _handleAction() {
    final action = widget.onAction;
    unawaited(_dismiss());
    if (action != null) action();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = scheme.inverseSurface;
    final foreground = scheme.onInverseSurface;
    final actionColor = scheme.inversePrimary;

    return Stack(
      children: <Widget>[
        Positioned(
          left: 16,
          right: 16,
          bottom: 0,
          child: SafeArea(
            minimum: const EdgeInsets.only(bottom: 16),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = Curves.easeOutCubic.transform(_controller.value);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, 28 * (1 - t)),
                    child: Material(
                      color: background,
                      elevation: 6,
                      shadowColor: scheme.shadow,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                widget.message,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (widget.actionLabel != null) ...<Widget>[
                              const SizedBox(width: 8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: actionColor,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                onPressed: _handleAction,
                                child: Text(widget.actionLabel ?? ''),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}