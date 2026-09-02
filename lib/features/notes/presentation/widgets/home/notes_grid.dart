import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/widgets/common/swipeable_note_card.dart';

/// Renders the note collection as either a grid or a list (with swipeable
/// cards), and a reorderable list when custom ordering is active.
///
/// The widget only knows how to *render* cards; all editing/navigation/pin/
/// delete behaviour is injected through callbacks so the UI stays free of
/// business logic.
class NotesGrid extends StatelessWidget {
  const NotesGrid({
    super.key,
    required this.notes,
    required this.gridLayout,
    required this.isCustomOrder,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.onConfirmSwipe,
    required this.onSwipedStartToEnd,
    required this.onSwipedEndToStart,
    required this.onReorder,
  });

  final List<Note> notes;
  final bool gridLayout;
  final bool isCustomOrder;
  final ValueChanged<Note> onTap;
  final ValueChanged<Note> onLongPress;
  final ValueChanged<Note> onEdit;
  final ValueChanged<Note> onDelete;
  final ValueChanged<Note> onPin;
  final Future<bool?> Function(DismissDirection, Note) onConfirmSwipe;
  final ValueChanged<Note> onSwipedStartToEnd;
  final ValueChanged<Note> onSwipedEndToStart;
  final void Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    if (isCustomOrder) return _buildReorderableList(context);
    return gridLayout ? _buildGrid(context) : _buildList(context);
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220.w,
        mainAxisExtent: 148.h,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
      ),
      itemCount: notes.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) =>
          RepaintBoundary(child: _card(context, notes[index])),
    );
  }

  Widget _buildReorderableList(BuildContext context) {
    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
      itemCount: notes.length,
      onReorder: onReorder,
      itemBuilder: (context, index) => Padding(
        key: ValueKey(notes[index].id),
        padding: EdgeInsets.only(bottom: 10.h),
        child: SizedBox(
          height: 128.h,
          child: RepaintBoundary(child: _card(context, notes[index])),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 110.h),
      itemCount: notes.length,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: SizedBox(
          height: 128.h,
          child: RepaintBoundary(child: _card(context, notes[index])),
        ),
      ),
    );
  }

  Widget _card(BuildContext context, Note note) {
    // `context.select` must not run on the sliver's own context; wrap it in a
    // [Builder] so only this card subscribes to selection state.
    return Builder(
      builder: (context) {
        final selectionMode = context.select<HomeCubit, bool>(
          (c) => c.state.selectionMode,
        );
        final isSelected = context.select<HomeCubit, bool>(
          (c) => c.state.selectedIds.contains(note.id),
        );
        return SwipeableNoteCard(
          note: note,
          selectionMode: selectionMode,
          isSelected: isSelected,
          isCustomOrder: isCustomOrder,
          onTap: () => onTap(note),
          onEdit: () => onEdit(note),
          onDelete: () => onDelete(note),
          onPin: () => onPin(note),
          onLongPress: () => onLongPress(note),
          onConfirmSwipe: (direction) => onConfirmSwipe(direction, note),
          onSwipedStartToEnd: () => onSwipedStartToEnd(note),
          onSwipedEndToStart: () => onSwipedEndToStart(note),
        );
      },
    );
  }
}
