import 'package:flutter/material.dart';

import 'package:notey/features/notes/presentation/widgets/selection_bar_widget.dart';

/// The animated bottom bar: the selection actions bar while in selection mode,
/// an empty slot otherwise.
class HomeBottomBar extends StatelessWidget {
  const HomeBottomBar({
    super.key,
    required this.selectionMode,
    required this.count,
    required this.anyUnpinned,
    required this.onColor,
    required this.onPin,
    required this.onDelete,
  });

  final bool selectionMode;
  final int count;
  final bool anyUnpinned;
  final VoidCallback onColor;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .3),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: !selectionMode
          ? const SizedBox.shrink(key: ValueKey('no-bar'))
          : SelectionBarWidget(
              key: const ValueKey('selection-bar'),
              count: count,
              anyUnpinned: anyUnpinned,
              onColor: onColor,
              onPin: onPin,
              onDelete: onDelete,
            ),
    );
  }
}
