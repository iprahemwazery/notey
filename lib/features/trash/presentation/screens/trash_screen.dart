import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/services/auth_gate.dart';
import 'package:notey/core/services/haptics.dart';
import 'package:notey/core/utils/color_utils.dart';
import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/data/services/image_store.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/trash/data/repositories_impl/trash_repository.dart';
import 'package:notey/features/trash/presentation/cubits/trash_cubit.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Trash bin: notes stay here for [retentionDays] days before being purged.
/// From here a note can be restored or deleted forever (frees its images).
///
/// A thin shell over [TrashCubit] — all persistence/cleanup orchestration
/// lives in the trash data layer, keeping this widget presentation-only.
class TrashScreen extends StatefulWidget {
  const TrashScreen({
    super.key,
    required this.repository,
    required this.imageStore,
  });

  final NoteRepository repository;
  final ImageStore imageStore;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<TrashCubit>(
      create: (_) => TrashCubit(
        TrashRepositoryImpl(
          noteRepository: widget.repository,
          imageStore: widget.imageStore,
        ),
      )..load(),
      child: const _TrashView(),
    );
  }
}

class _TrashView extends StatelessWidget {
  const _TrashView();

  Future<void> _restore(
    BuildContext context,
    TrashCubit cubit,
    Note note,
  ) async {
    Haptics.tap();
    await cubit.restore(note);
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    GlassSnackbar.show(message: l10n.restoredToast(_displayTitle(context, note)));
  }

  Future<void> _purgeForever(
    BuildContext context,
    TrashCubit cubit,
    Note note,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.purgeForeverTitle),
        content: Text(l10n.purgeForeverMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.purgeForeverConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !context.mounted) return;
    await Haptics.heavy();
    await cubit.purge(note);
  }

  Future<void> _emptyTrash(
    BuildContext context,
    TrashCubit cubit,
    List<Note> notes,
  ) async {
    if (notes.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashMessage(notes.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.emptyTrashConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !context.mounted) return;
    await Haptics.heavy();
    await cubit.emptyTrash();
  }

  String _displayTitle(BuildContext context, Note note) {
    final l10n = AppLocalizations.of(context);
    if (note.isLocked) return l10n.lockedNote;
    final title = note.title.trim();
    return title.isEmpty ? l10n.untitled : title;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<TrashCubit>();

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            l10n.trashTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: <Widget>[
            BlocBuilder<TrashCubit, TrashState>(
              builder: (context, state) => IconButton(
                tooltip: l10n.emptyTrashTooltip,
                onPressed: state.loading || state.notes.isEmpty
                    ? null
                    : () => _emptyTrash(context, cubit, state.notes),
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
            ),
          ],
        ),
        body: BlocBuilder<TrashCubit, TrashState>(
          builder: (context, state) {
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.notes.isEmpty) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 56.w,
                        color: scheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        l10n.trashEmptyTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        l10n.trashRetentionLabel(state.retentionDays),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final notes = state.notes;
            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final background =
                    AppConstants.noteColors[note.colorIndex %
                        AppConstants.noteColors.length];
                final onColor = ColorUtils.foregroundOn(background);
                final mutedOnColor = ColorUtils.foregroundMutedOn(background);
                final dangerColor = ColorUtils.dangerOn(background);
                return Card(
                  elevation: 0,
                  color: background,
                  margin: EdgeInsets.only(bottom: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    leading: note.isLocked
                        ? Icon(Icons.lock_rounded, color: onColor)
                        : Icon(
                            Icons.sticky_note_2_outlined,
                            color: onColor,
                          ),
                    title: Text(
                      _displayTitle(context, note),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: onColor,
                      ),
                    ),
                    subtitle: note.deletedAt == null
                        ? null
                        : Text(
                            _relativeDays(context, note.deletedAt!),
                            style: TextStyle(color: mutedOnColor),
                          ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          tooltip: l10n.restoreTooltip,
                          icon: Icon(Icons.restore_rounded, color: onColor),
                          onPressed: () => _restore(context, cubit, note),
                        ),
                        IconButton(
                          tooltip: l10n.purgeForeverTooltip,
                          icon: Icon(
                            Icons.delete_forever_rounded,
                            color: dangerColor,
                          ),
                          onPressed: () => _purgeForever(context, cubit, note),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _relativeDays(BuildContext context, DateTime deletedAt) {
    final l10n = AppLocalizations.of(context);
    final days = DateTime.now().difference(deletedAt).inDays;
    if (days <= 0) return l10n.deletedToday;
    if (days == 1) return l10n.deletedYesterday;
    return l10n.deletedDaysAgo(days);
  }
}
