import 'package:flutter/material.dart';

import 'package:notey/features/notes/presentation/widgets/header_widget.dart';
import 'package:notey/features/notes/presentation/widgets/selection_header_widget.dart';
import 'package:notey/features/notes/presentation/widgets/sort_menu_widget.dart';

/// The animated title bar: shows the selection header while in selection mode,
/// the default app header otherwise. Fade/slide transitions between the two.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({
    super.key,
    required this.selectionMode,
    required this.count,
    required this.totalCount,
    required this.notesCount,
    required this.sort,
    required this.isGrid,
    required this.onToggleLayout,
    required this.onSortChanged,
    required this.onOpenSettings,
    required this.onOpenVault,
    required this.onOpenTrash,
    required this.onSelectAll,
    required this.onClose,
  });

  final bool selectionMode;
  final int count;
  final int totalCount;
  final int notesCount;
  final NoteSort sort;
  final bool isGrid;
  final VoidCallback onToggleLayout;
  final ValueChanged<NoteSort> onSortChanged;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenVault;
  final VoidCallback onOpenTrash;
  final VoidCallback onSelectAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final widget = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -.15),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: selectionMode
          ? SelectionHeaderWidget(
              key: const ValueKey('selection-header'),
              count: count,
              totalCount: totalCount,
              onSelectAll: onSelectAll,
              onClose: onClose,
            )
          : HeaderWidget(
              key: const ValueKey('default-header'),
              notesCount: notesCount,
              sort: sort,
              isGrid: isGrid,
              onToggleLayout: onToggleLayout,
              onSortChanged: onSortChanged,
              onOpenSettings: onOpenSettings,
              onOpenVault: onOpenVault,
              onOpenTrash: onOpenTrash,
            ),
    );
    return widget;
  }
}
