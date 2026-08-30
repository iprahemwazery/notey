import 'dart:async';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/note_lock_service.dart';

import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/screen_protector_service.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/core/utils/arabic_date_time.dart';

import 'package:notey/core/utils/attachment_utils.dart';

import 'package:notey/core/utils/checklist.dart';

import 'package:notey/core/utils/color_utils.dart';

import 'package:notey/core/utils/file_icons.dart';

import 'package:notey/core/utils/markdown.dart';

import 'package:notey/data/repositories/note_history_repository.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';

import 'package:notey/features/notes/model/note_history.dart';

import 'package:notey/features/notes/cubit/viewer_cubit.dart';

import 'package:notey/features/notes/cubit/viewer_state.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'package:notey/features/notes/view/note_editor_screen.dart';

import 'document_preview_screen.dart';
import 'image_viewer_screen.dart';

class NoteViewScreen extends StatefulWidget {
  const NoteViewScreen({
    super.key,
    required this.note,
    this.repository,
    this.imageStore,
  });

  final Note note;
  final NoteRepository? repository;
  final ImageStore? imageStore;

  @override
  State<NoteViewScreen> createState() => _NoteViewScreenState();
}

class _NoteViewScreenState extends State<NoteViewScreen> {
  late final NoteRepository _repository =
      widget.repository ?? NoteRepository();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewerCubit(
        note: widget.note,
        repository: _repository,
        historyRepo: NoteHistoryRepository(),
      ),
      child: const _NoteViewBody(),
    );
  }
}

class _NoteViewBody extends StatefulWidget {
  const _NoteViewBody();

  @override
  State<_NoteViewBody> createState() => _NoteViewBodyState();
}

class _NoteViewBodyState extends State<_NoteViewBody> {
  bool _searchActive = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ViewerState>? _protectionSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ViewerCubit>();
      final locked = cubit.state.isLocked;
      if (locked) {
        ScreenProtectorService.protect();
        _protectionSubscription = cubit.stream.listen((state) {
          if (state.isLocked && state.isUnlocked) {
            ScreenProtectorService.unprotect();
          }
        });
      }
      UiPrefs.readerFontScale().then(
            cubit.setFontScale,
          );
    });
  }

  @override
  void dispose() {
    ScreenProtectorService.unprotect();
    _protectionSubscription?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<int> _findMatches(String text, String query) {
    if (query.isEmpty) return const [];
    final matches = <int>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    var start = 0;
    while (start <= lower.length) {
      final idx = lower.indexOf(qLower, start);
      if (idx < 0) break;
      matches.add(idx);
      start = idx + 1;
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<ViewerCubit>();
    final state = cubit.state;
    final note = state.note;
    final displayNote = state.displayNote;
    final locked = state.isLocked && !state.isUnlocked;
    final l10n = AppLocalizations.of(context);

    final background = AppConstants
        .noteColors[note.colorIndex % AppConstants.noteColors.length];
    final onColor = ColorUtils.foregroundOn(background);
    final mutedOnColor = ColorUtils.foregroundMutedOn(background);

    final displayTitle = locked
        ? l10n.lockedNote
        : (displayNote.title.isEmpty ? l10n.untitled : displayNote.title);

    final fileAttachments = displayNote.attachments
        .where((a) => !AttachmentUtils.isImage(a))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.viewerTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          if (!locked)
            IconButton(
              tooltip: l10n.searchInNote,
              onPressed: () {
                setState(() {
                  _searchActive = !_searchActive;
                  if (!_searchActive) {
                    _searchQuery = '';
                    _searchController.clear();
                  }
                });
              },
              icon: Icon(
                _searchActive ? Icons.search_off_rounded : Icons.search_rounded,
              ),
            ),
          if (!locked)
            IconButton(
              tooltip: l10n.shareTooltip,
              onPressed: () => _share(displayNote),
              icon: const Icon(Icons.share_rounded),
            ),
          if (!locked)
            IconButton(
              tooltip: l10n.exportFileTooltip,
              onPressed: () => _exportAsFile(context, displayNote),
              icon: const Icon(Icons.ios_share_rounded),
            ),
          IconButton(
            tooltip: locked ? l10n.unlockTooltip : l10n.protectMenuTooltip,
            onPressed: locked
                ? () => _unlockViaDialog(context)
                : () => _openLockMenu(context),
            icon: Icon(
              note.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            ),
          ),
          IconButton(
            tooltip: l10n.edit,
            onPressed: () => _edit(context),
            icon: const Icon(Icons.edit_rounded),
          ),
          if (!locked)
            IconButton(
              tooltip: l10n.editHistoryTitle,
              onPressed: () => _showHistory(context),
              icon: const Icon(Icons.history_rounded),
            ),
          IconButton(
            tooltip: l10n.delete,
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline_rounded),
            color: scheme.error,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchActive)
            Material(
              elevation: 2,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: l10n.searchInNote,
                            prefixIcon: Icon(Icons.search_rounded, size: 20.w),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...<Widget>[
                        SizedBox(width: 8.w),
                        Text(
                          _buildMatchCount(displayNote, l10n),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
            Hero(
              tag: 'note-bg-${note.id}',
              child: Material(
                color: background,
                borderRadius: BorderRadius.circular(22.r),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    border: Border.all(color: onColor.withValues(alpha: .25)),
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            if (note.pinned) ...<Widget>[
                              Icon(
                                Icons.push_pin_rounded,
                                size: 18.w,
                                color: Color(0xFFE08600),
                              ),
                              SizedBox(width: 6.w),
                            ],
                            if (locked) ...<Widget>[
                              Icon(
                                Icons.lock_rounded,
                                size: 18.w,
                                color: onColor,
                              ),
                              SizedBox(width: 6.w),
                            ],
                            Expanded(
                              child: Text(
                                displayTitle,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      height: 1.3,
                                      color: onColor,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        if (locked)
                          const SizedBox.shrink()
                        else if (_searchActive && _searchQuery.isNotEmpty)
                          _highlightText(
                            displayNote.content.isEmpty
                                ? l10n.noDetails
                                : displayNote.content,
                            _searchQuery,
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: mutedOnColor,
                            ),
                            scheme.tertiary,
                          )
                        else if (Checklist.hasTasks(displayNote.content))
                          _TaskList(
                            content: displayNote.content,
                            fontScale: state.fontScale,
                            onToggle: (i) => cubit.toggleTask(i),
                          )
                        else if (displayNote.content.isEmpty)
                          Text(
                            l10n.noDetails,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.7,
                              color: mutedOnColor,
                            ),
                          )
                        else
                          MarkdownText(
                            data: displayNote.content,
                            fontSize: 16 * state.fontScale,
                            color: mutedOnColor,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (locked) ...<Widget>[
              const SizedBox(height: 16),
              _UnlockPanel(
                onUnlock: (pw) => cubit.unlock(pw),
              ),
            ] else ...<Widget>[
              const SizedBox(height: 18),
              _InfoRow(
                icon: Icons.add_circle_outline_rounded,
                label: l10n.createdAtLabel,
                value: ArabicDateTime.full(displayNote.createdAt, l10n: l10n),
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.update_rounded,
                label: l10n.lastModifiedLabel,
                value: ArabicDateTime.full(displayNote.updatedAt, l10n: l10n),
              ),
              if (displayNote.tags.isNotEmpty) ...<Widget>[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final tag in displayNote.tags)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: .6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.sell_rounded,
                              size: 13.w,
                              color: scheme.primary,
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
              // The image grid stays isolated in its own BlocSelector so checklist
              // toggles / font changes never re-layout the (costly) images.
              BlocSelector<ViewerCubit, ViewerState, List<String>>(
                selector: (s) => s.note.imageAttachments,
                builder: (context, attachments) {
                  if (attachments.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: 20.h),
                      Text(
                        l10n.imagesCountLabel(attachments.length),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: attachments.length,
                        itemBuilder: (context, index) => Semantics(
                          button: true,
                          label: '${l10n.semOpenImageViewer} ${index + 1}',
                          child: GestureDetector(
                            onTap: () => _openImageViewer(context, index),
                            child: Hero(
                              tag: 'note-image-${displayNote.id}-$index',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.r),
                                child: Image.file(
                                  File(attachments[index]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  cacheWidth:
                                      (MediaQuery.sizeOf(context).width *
                                              MediaQuery.devicePixelRatioOf(
                                                context,
                                              ) /
                                              2)
                                          .round(),
                                  errorBuilder: (_, _, _) => Container(
                                    color: scheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (fileAttachments.isNotEmpty) ...<Widget>[
                SizedBox(height: 20.h),
                Text(
                  l10n.filesCountLabel(fileAttachments.length),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                for (final path in fileAttachments)
                  _FileTile(
                    path: path,
                    onOpen: () => _openFile(context, path),
                    onShare: () => _shareFile(path),
                  ),
              ],
            ],
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  String _buildMatchCount(Note displayNote, AppLocalizations l10n) {
    final text = '${displayNote.title}\n${displayNote.content}';
    final matches = _findMatches(text, _searchQuery);
    if (matches.isEmpty) return l10n.searchNoMatches;
    return l10n.searchMatchOf(matches.length, matches.length);
  }

  Widget _highlightText(String text, String query, TextStyle? style, Color highlightColor) {
    if (query.isEmpty) return Text(text, style: style);
    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    var start = 0;
    while (start <= lower.length) {
      final idx = lower.indexOf(qLower, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: style?.copyWith(
          backgroundColor: highlightColor.withValues(alpha: 0.4),
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }
    return RichText(text: TextSpan(children: spans));
  }

  void _share(Note displayNote) {
    SharePlus.instance.share(
      ShareParams(text: '${displayNote.title}\n\n${displayNote.content}'),
    );
  }

  Future<void> _exportAsFile(BuildContext context, Note displayNote) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dir = await getTemporaryDirectory();
      String two(int n) => n.toString().padLeft(2, '0');
      final now = DateTime.now();
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
      final safeTitle = displayNote.title.trim().isEmpty
          ? l10n.untitled
          : displayNote.title
              .trim()
              .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${dir.path}/$safeTitle-$stamp.txt');
      await file.writeAsString(
        <String>[
          displayNote.title,
          '=' * 10,
          l10n.exportedWithLine(AppConstants.appName),
          '',
          displayNote.content,
        ].join('\n'),
        flush: true,
      );
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)], text: displayNote.title),
      );
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportFailed)));
    }
  }

  Future<void> _edit(BuildContext context) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final cubit = context.read<ViewerCubit>();
    final state = cubit.state;
    final l10n = AppLocalizations.of(context);

    if (state.isLocked && !state.isUnlocked) {
      final password = await showPasswordDialog(
        context,
        title: l10n.lockedNote,
        message: l10n.unlockDialogMessage,
        confirmButtonLabel: l10n.unlockConfirm,
      );
      if (password == null) return;
      final ok = await cubit.unlock(password);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.wrongPasswordToast)),
        );
        return;
      }
    }

    if (!context.mounted) return;

    final editable = context.read<ViewerCubit>().state.displayNote;
    final repository = context.read<ViewerCubit>().repository;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => NoteEditorScreen(
          note: editable,
          repository: repository,
          unlockPassword: cubit.currentPassword,
        ),
      ),
    );
    if (changed == true) {
      await cubit.reloadNote();
    }
  }

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ViewerCubit>();
    final note = cubit.state.note;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteNoteTitle),
        content: Text(l10n.deleteNoteTrashMessage),
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
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Haptics.heavy();
    unawaited(ReminderService.cancel(note.id));
    await cubit.delete();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.movedToTrashOne)),
    );
    Navigator.of(context).pop(true);
  }

  void _openImageViewer(BuildContext context, int index) {
    final note = context.read<ViewerCubit>().state.note;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImageViewerScreen(
          images: note.imageAttachments,
          initialIndex: index,
        ),
      ),
    );
  }

  Future<void> _showHistory(BuildContext context) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final cubit = context.read<ViewerCubit>();
    await cubit.loadHistory();
    if (!context.mounted) return;
    final state = cubit.state;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
              child: Row(
                children: <Widget>[
                  Icon(Icons.history_rounded, color: scheme.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      l10n.editHistoryTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.semCloseSheet,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: state.history.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.history_rounded,
                              size: 48.w,
                              color:
                                  scheme.onSurfaceVariant.withValues(alpha: .4),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.noEditHistory,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: state.history.length,
                      itemBuilder: (context, index) {
                        final entry = state.history[index];
                        return _HistoryTile(
                          entry: entry,
                          isCurrent: index == 0,
                          onTap: () {
                            Navigator.pop(ctx);
                            _previewHistory(context, entry);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewHistory(BuildContext context, NoteHistory entry) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ViewerCubit>();
    final note = cubit.state.note;
    final bg = AppConstants
        .noteColors[note.colorIndex % AppConstants.noteColors.length];
    final onColor = ColorUtils.foregroundOn(bg);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.history_rounded, color: scheme.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      ArabicDateTime.full(entry.timestamp, l10n: l10n),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.semCloseSheet,
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Material(
                color: bg,
                borderRadius: BorderRadius.circular(18.r),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.r),
                    border: Border.all(
                        color: onColor.withValues(alpha: .25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (entry.title.isNotEmpty)
                        Text(
                          entry.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: onColor,
                              ),
                        ),
                      if (entry.title.isNotEmpty) SizedBox(height: 8.h),
                      if (entry.content.isEmpty)
                        Text(
                          l10n.noDetails,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                color: onColor.withValues(alpha: .6),
                              ),
                        )
                      else
                        MarkdownText(
                          data: entry.content,
                          fontSize: 16.sp,
                          color: onColor.withValues(alpha: .82),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _restoreFromHistory(context, cubit, entry);
                  },
                  icon: const Icon(Icons.restore_rounded),
                  label: Text(l10n.restoreHistoryVersion),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restoreFromHistory(
    BuildContext context,
    ViewerCubit cubit,
    NoteHistory entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final note = cubit.state.note;
    final updated = note.copyWith(
      title: entry.title,
      content: entry.content,
      updatedAt: DateTime.now(),
    );
    if (note.isLocked && cubit.currentPassword != null) {
      final locked = await NoteLockService.lock(updated, cubit.currentPassword!);
      await cubit.repository.update(locked);
    } else {
      await cubit.repository.update(updated);
    }
    await cubit.reloadNote();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.historyRestoredToast)),
      );
    }
  }

  Future<void> _unlockViaDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ViewerCubit>();
    final password = await showPasswordDialog(
      context,
      title: l10n.lockedNote,
      message: l10n.unlockDialogMessage,
      confirmButtonLabel: l10n.unlockConfirm,
    );
    if (password == null || !context.mounted) return;
    final ok = await cubit.unlock(password);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.wrongPasswordToast)),
      );
    }
  }

  void _openLockMenu(BuildContext context) {
    final cubit = context.read<ViewerCubit>();
    final state = cubit.state;
    final isLocked = state.isLocked;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  isLocked ? l10n.manageProtection : l10n.protectSheetTitle,
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 14.h),
                if (!isLocked) ...<Widget>[
                  ListTile(
                    leading: const Icon(Icons.lock_outline_rounded),
                    title: Text(l10n.setPasswordItem),
                    subtitle: Text(l10n.setPasswordSubtitle),
                    onTap: () {
                      Navigator.pop(ctx);
                      _setPassword(context);
                    },
                  ),
                ] else ...<Widget>[
                  ListTile(
                    leading: const Icon(Icons.password_rounded),
                    title: Text(l10n.changePassword),
                    onTap: () {
                      Navigator.pop(ctx);
                      _changePassword(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.lock_open_rounded,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                    title: Text(
                      l10n.removePassword,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePassword(context);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _setPassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();
    final password = await showPasswordDialog(
      context,
      title: AppLocalizations.of(context).setPasswordDialogTitle,
      message: AppLocalizations.of(context).setPasswordDialogMessage,
      confirmButtonLabel: AppLocalizations.of(context).secureConfirm,
      confirmRequired: true,
    );
    if (password == null || !context.mounted) return;
    await Haptics.light();
    await cubit.setPassword(password);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).securedToast)),
    );
  }

  Future<void> _changePassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();
    final l10n = AppLocalizations.of(context);

    if (cubit.state.unlocked == null) {
      await _ensureDecrypted(context);
      if (cubit.state.unlocked == null || !context.mounted) return;
    }

    final password = await showPasswordDialog(
      context,
      title: l10n.changePassword,
      message: l10n.newPasswordMessage,
      confirmButtonLabel: l10n.updateConfirm,
      confirmRequired: true,
    );
    if (password == null || !context.mounted) return;
    await Haptics.light();
    await cubit.changePassword(password);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.passwordUpdatedToast)),
    );
  }

  Future<void> _removePassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removePasswordTitle),
        content: Text(l10n.removePasswordMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await _ensureDecrypted(
      context,
      message: l10n.enterCurrentToRemoveMessage,
    );
    if (cubit.state.unlocked == null || !context.mounted) return;

    await Haptics.heavy();
    await cubit.removePassword();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.protectionRemovedToast)),
    );
  }

  Future<void> _ensureDecrypted(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    final cubit = context.read<ViewerCubit>();
    if (!cubit.state.isLocked) return;
    final localization = AppLocalizations.of(context);
    while (cubit.state.unlocked == null) {
      if (!context.mounted) return;
      final password = await showPasswordDialog(
        context,
        title: title ?? localization.lockedNote,
        message: message ?? localization.enterCurrentPasswordMessage,
        confirmButtonLabel: localization.continueLabel,
      );
      if (!context.mounted || password == null) return;
      final ok = await cubit.unlock(password);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).wrongPasswordToast),
          ),
        );
      }
    }
  }

  Future<void> _openFile(BuildContext context, String path) async {
    await Haptics.tap();
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DocumentPreviewScreen(path: path),
      ),
    );
  }

  Future<void> _shareFile(String path) async {
    await Haptics.tap();
    await SharePlus.instance.share(ShareParams(files: <XFile>[XFile(path)]));
  }
}

class _UnlockPanel extends StatefulWidget {
  const _UnlockPanel({required this.onUnlock});

  final Future<bool> Function(String password) onUnlock;

  @override
  State<_UnlockPanel> createState() => _UnlockPanelState();
}

class _UnlockPanelState extends State<_UnlockPanel> {
  final TextEditingController _password = TextEditingController();
  bool _checking = false;
  bool _error = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_checking || _password.text.isEmpty) return;
    setState(() {
      _checking = true;
      _error = false;
    });
    final ok = await widget.onUnlock(_password.text);
    if (!mounted) return;
    if (!ok) {
      await Haptics.heavy();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = true;
      });
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lock_rounded, color: scheme.primary),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  l10n.unlockPanelTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          TextField(
            controller: _password,
            obscureText: true,
            enabled: !_checking,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: l10n.passwordHint,
              prefixIcon: const Icon(Icons.key_rounded),
              errorText: _error ? l10n.wrongPasswordToast : null,
            ),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            height: 50.h,
            child: FilledButton.icon(
              onPressed: _checking ? null : _submit,
              icon: _checking
                  ? SizedBox(
                      width: 18.w,
                      height: 18.h,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.lock_open_rounded),
              label: Text(l10n.unlockPanelButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({
    required this.path,
    required this.onOpen,
    required this.onShare,
  });

  final String path;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
        child: Semantics(
          button: true,
          label:
              '${AppLocalizations.of(context).semOpenFile} ${AttachmentUtils.fileName(path)}',
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onOpen,
            child: Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: <Widget>[
                  Icon(attachmentIcon(path), size: 22.w, color: scheme.primary),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      AttachmentUtils.fileName(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    tooltip: AppLocalizations.of(context).shareTooltip,
                    onPressed: onShare,
                    icon: Icon(Icons.ios_share_rounded, size: 20.w),
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({
    required this.content,
    required this.fontScale,
    required this.onToggle,
  });
  final String content;
  final double fontScale;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = content.split('\n');

    final children = <Widget>[];
    var taskIndex = -1;
    for (final line in lines) {
      if (Checklist.isTaskLine(line)) {
        taskIndex++;
        final index = taskIndex;
        final checked = line.toLowerCase().contains('[x]');
        final text =
            line.replaceFirst(RegExp(r'^\s*-\s\[[ xX]\]\s?'), '');
        final hasText = text.trim().isNotEmpty;
        children.add(
          Semantics(
            checked: checked,
            label: hasText
                ? text
                : AppLocalizations.of(context).semChecklistItem,
            hint: AppLocalizations.of(context).semChecklistHint,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(index),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 22.w,
                      color: checked
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    if (hasText) ...<Widget>[
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                height: 1.6,
                                fontSize: 16 * fontScale,
                                color: mutedTextOn(scheme),
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        children.add(SizedBox(height: 8.h));
      } else {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Text(
              line,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.7),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

Color mutedTextOn(ColorScheme scheme) =>
    scheme.onSurface.withValues(alpha: .82);

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18.w, color: scheme.primary),
        SizedBox(width: 10.w),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  final NoteHistory entry;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final preview = entry.content.trim();
    final previewText =
        preview.length > 80 ? '${preview.substring(0, 80)}...' : preview;

    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isCurrent
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            entry.title.isNotEmpty ? entry.title[0] : '?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 18.sp,
            ),
          ),
        ),
      ),
      title: Text(
        entry.title.isNotEmpty ? entry.title : l10n.untitled,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCurrent ? scheme.primary : null,
        ),
      ),
      subtitle: previewText.isNotEmpty
          ? Text(
              previewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            ArabicDateTime.full(entry.timestamp, l10n: l10n),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (isCurrent) ...<Widget>[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                l10n.currentVersion,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
