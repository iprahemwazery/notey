import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/widgets/note_card.dart';

/// A swipeable note card: [Dismissible] with pin/delete swipe actions wrapping
/// the shared [NoteCard], plus a Hero for the card-background transition.
class SwipeableNoteCard extends StatelessWidget {
  const SwipeableNoteCard({
    super.key,
    required this.note,
    required this.selectionMode,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.onLongPress,
    required this.onConfirmSwipe,
    required this.onSwipedStartToEnd,
    required this.onSwipedEndToStart,
    this.isCustomOrder = false,
  });

  final Note note;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onLongPress;

  /// Returns true when a swipe in the given direction is allowed.
  final Future<bool?> Function(DismissDirection) onConfirmSwipe;
  final VoidCallback onSwipedStartToEnd;
  final VoidCallback onSwipedEndToStart;

  /// Whether this card participates in an ordered (reorderable) list; disables
  /// swipe-to-sort interactions handled by the parent list otherwise.
  final bool isCustomOrder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: Key(note.id.toString()),
      direction: selectionMode || isCustomOrder
          ? DismissDirection.none
          : DismissDirection.horizontal,
      confirmDismiss: onConfirmSwipe,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onSwipedEndToStart();
        } else {
          onSwipedStartToEnd();
        }
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: EdgeInsetsDirectional.only(start: 24.w),
        decoration: BoxDecoration(
          color: note.pinned
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          note.pinned ? Icons.push_pin_outlined : Icons.push_pin_rounded,
          color: note.pinned
              ? scheme.onSecondaryContainer
              : scheme.onPrimaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: EdgeInsetsDirectional.only(end: 24.w),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(Icons.delete_rounded, color: scheme.onErrorContainer),
      ),
      child: Hero(
        tag: 'note-bg-${note.id}',
        child: NoteCard(
          note: note,
          selectionMode: selectionMode,
          isSelected: isSelected,
          onLongPress: onLongPress,
          onTap: onTap,
          onEdit: onEdit,
          onDelete: onDelete,
          onPin: onPin,
        ),
      ),
    );
  }
}
