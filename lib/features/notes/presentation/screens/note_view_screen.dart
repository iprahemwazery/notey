import 'dart:async';

import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/widgets/note_snackbar.dart';

import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/screen_protector_service.dart';

import 'package:notey/core/utils/arabic_date_time.dart';

import 'package:notey/core/utils/attachment_utils.dart';

import 'package:notey/core/utils/color_utils.dart';

import 'package:notey/core/utils/markdown.dart';

import 'package:notey/core/utils/viewer_search.dart';

import 'package:notey/features/notes/data/repositories_impl/note_history_repository.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/domain/entities/note.dart';

import 'package:notey/features/notes/domain/entities/note_history.dart';

import 'package:notey/features/settings/data/repositories_impl/settings_repository.dart';
import 'package:notey/features/settings/domain/usecases/get_reader_font_scale.dart';
import 'package:notey/features/notes/presentation/cubits/viewer_cubit.dart';

import 'package:notey/features/notes/presentation/cubits/viewer_state.dart';

import 'package:notey/widgets/password_dialog.dart';

import 'package:notey/features/notes/presentation/screens/note_editor_screen.dart';

import 'document_preview_screen.dart';
import 'image_viewer_screen.dart';

import '../widgets/viewer/note_content_card_widget.dart';
import '../widgets/viewer/unlock_panel_widget.dart';
import '../widgets/viewer/viewer_file_tile_widget.dart';
import '../widgets/viewer/viewer_history_tile_widget.dart';
import '../widgets/viewer/viewer_image_grid.dart';
import '../widgets/viewer/viewer_info_row_widget.dart';
import '../widgets/viewer/viewer_lock_menu_sheet.dart';
import '../widgets/viewer/viewer_search_bar.dart';
import '../widgets/viewer/viewer_tag_chips.dart';

import 'package:notey/widgets/common/app_dialogs.dart';
import 'package:notey/widgets/common/sheet_header.dart';

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
  late final NoteRepository _repository = widget.repository ?? NoteRepositoryImpl();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ViewerCubit(
        note: widget.note,
        repository: _repository,
        historyRepo: NoteHistoryRepositoryImpl(),
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

  /// True once the viewer edited or deleted the note, so popping reports a
  /// change back to the home list which then reloads fresh colors/titles.
  bool _changed = false;

  /// Flip to true right before a programmatic pop so PopScope lets it through.
  bool _canPop = false;

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cubit = context.read<ViewerCubit>();
      if (cubit.state.isLocked) {
        ScreenProtectorService.protect();
        _protectionSubscription = cubit.stream.listen((state) {
          if (state.isLocked && state.isUnlocked) {
            ScreenProtectorService.unprotect();
          }
        });
      }
      GetReaderFontScale(SettingsRepositoryImpl())().then(cubit.setFontScale);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.watch<ViewerCubit>();
    final state = cubit.state;
    final note = state.note;
    final displayNote = state.displayNote;
    final locked = state.isLocked && !state.isUnlocked;

    final background =
        AppConstants.noteColors[note.colorIndex % AppConstants.noteColors.length];

    final displayTitle = locked
        ? l10n.lockedNote
        : (displayNote.title.isEmpty ? l10n.untitled : displayNote.title);

    final fileAttachments = displayNote.attachments
        .where((a) => !AttachmentUtils.isImage(a))
        .toList();

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _canPop = true);
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
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
                  _searchActive
                      ? Icons.search_off_rounded
                      : Icons.search_rounded,
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
              onPressed: state.locking
                  ? null
                  : locked
                      ? () => _unlockViaDialog(context)
                      : () => _openLockMenu(context),
              icon: state.locking
                  ? SizedBox(
                      width: 20.w,
                      height: 20.h,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Icon(
                      note.isLocked
                          ? Icons.lock_rounded
                          : Icons.lock_open_rounded,
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
          children: <Widget>[
            if (_searchActive)
              ViewerSearchBar(
                controller: _searchController,
                query: _searchQuery,
                matchCount: _buildMatchCount(displayNote),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    NoteContentCardWidget(
                      noteId: note.id,
                      pinned: note.pinned,
                      locked: locked,
                      title: displayTitle,
                      content: displayNote.content,
                      background: background,
                      highlightQuery: _searchActive ? _searchQuery : '',
                      highlightColor: scheme.tertiary,
                      fontScale: state.fontScale,
                      onToggleTask: (i) => cubit.toggleTask(i),
                    ),
                    if (locked) ...<Widget>[
                      const SizedBox(height: 16),
                      UnlockPanelWidget(onUnlock: (pw) => cubit.unlock(pw)),
                    ] else ...<Widget>[
                      const SizedBox(height: 18),
                      ViewerInfoRowWidget(
                        icon: Icons.add_circle_outline_rounded,
                        label: l10n.createdAtLabel,
                        value: ArabicDateTime.full(
                          displayNote.createdAt,
                          l10n: l10n,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ViewerInfoRowWidget(
                        icon: Icons.update_rounded,
                        label: l10n.lastModifiedLabel,
                        value: ArabicDateTime.full(
                          displayNote.updatedAt,
                          l10n: l10n,
                        ),
                      ),
                      if (displayNote.tags.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 12),
                        ViewerTagChips(tags: displayNote.tags),
                      ],
                      // The image grid stays isolated so checklist toggles /
                      // font changes never re-layout it.
                      ViewerImageGrid(
                        noteId: note.id,
                        onOpen: (index) => _openImageViewer(context, index),
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
                          ViewerFileTileWidget(
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
      ),
    );
  }

  String _buildMatchCount(Note displayNote) {
    final text = '${displayNote.title}\n${displayNote.content}';
    final matches = ViewerSearch.findMatches(text, _searchQuery);
    if (matches.isEmpty) return l10n.searchNoMatches;
    return l10n.searchMatchOf(matches.length, matches.length);
  }

  void _share(Note displayNote) {
    SharePlus.instance.share(
      ShareParams(text: '${displayNote.title}\n\n${displayNote.content}'),
    );
  }

  Future<void> _exportAsFile(BuildContext context, Note displayNote) async {
    await Haptics.tap();
    if (!context.mounted) return;
    try {
      final dir = await getTemporaryDirectory();
      String two(int n) => n.toString().padLeft(2, '0');
      final now = DateTime.now();
      final stamp =
          '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
      final safeTitle = displayNote.title.trim().isEmpty
          ? l10n.untitled
          : displayNote.title.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
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
      GlassSnackbar.show(message: l10n.exportFailed, isError: true);
    }
  }

  Future<void> _edit(BuildContext context) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final cubit = context.read<ViewerCubit>();
    final state = cubit.state;

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
        GlassSnackbar.show(message: l10n.wrongPasswordToast, isError: true);
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
      if (mounted) setState(() => _changed = true);
    }
  }

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();
    final note = cubit.state.note;

    final confirmed = await AppDialogs.confirm(
      context,
      title: l10n.deleteNoteTitle,
      message: l10n.deleteNoteTrashMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed) return;
    await Haptics.heavy();
    unawaited(ReminderService.cancel(note.id));
    await cubit.delete();
    if (!context.mounted) return;
    GlassSnackbar.show(message: l10n.movedToTrashOne);
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
    final scheme = Theme.of(context).colorScheme;
    final outerContext = context;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedTopSheet.shape(scheme),
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
              child: SheetHeader(
                icon: Icons.history_rounded,
                title: Text(
                  l10n.editHistoryTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onClose: () => Navigator.pop(ctx),
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
                              color: scheme.onSurfaceVariant.withValues(alpha: .4),
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              l10n.noEditHistory,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
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
                        return ViewerHistoryTileWidget(
                          entry: entry,
                          isCurrent: index == 0,
                          onTap: () {
                            Navigator.pop(ctx);
                            _previewHistory(outerContext, entry);
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
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<ViewerCubit>();
    final note = cubit.state.note;
    final bg =
        AppConstants.noteColors[note.colorIndex % AppConstants.noteColors.length];
    final onColor = ColorUtils.foregroundOn(bg);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surfaceContainerLow,
      shape: RoundedTopSheet.shape(scheme),
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
              SheetHeader(
                icon: Icons.history_rounded,
                title: Text(
                  ArabicDateTime.full(entry.timestamp, l10n: l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onClose: () => Navigator.pop(ctx),
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
                    border: Border.all(color: onColor.withValues(alpha: .25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (entry.title.isNotEmpty)
                        Text(
                          entry.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: onColor,
                              ),
                        ),
                      if (entry.title.isNotEmpty) SizedBox(height: 8.h),
                      if (entry.content.isEmpty)
                        Text(
                          l10n.noDetails,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                    await cubit.restoreHistory(entry);
                    if (context.mounted) {
                      GlassSnackbar.show(message: l10n.historyRestoredToast);
                    }
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

  Future<void> _unlockViaDialog(BuildContext context) async {
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
      GlassSnackbar.show(message: l10n.wrongPasswordToast, isError: true);
    }
  }

  void _openLockMenu(BuildContext context) {
    final cubit = context.read<ViewerCubit>();
    final isLocked = cubit.state.isLocked;
    final outerContext = context;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedTopSheet.shape(Theme.of(context).colorScheme),
      builder: (ctx) => ViewerLockMenuSheet(
        isLocked: isLocked,
        onSet: () {
          Navigator.pop(ctx);
          _setPassword(outerContext);
        },
        onChange: () {
          Navigator.pop(ctx);
          _changePassword(outerContext);
        },
        onRemove: () {
          Navigator.pop(ctx);
          _removePassword(outerContext);
        },
      ),
    );
  }

  Future<void> _setPassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();
    final password = await showPasswordDialog(
      context,
      title: l10n.setPasswordDialogTitle,
      message: l10n.setPasswordDialogMessage,
      confirmButtonLabel: l10n.secureConfirm,
      confirmRequired: true,
    );
    if (password == null || !context.mounted) return;
    await Haptics.light();
    try {
      await cubit.setPassword(password);
    } catch (_) {
      if (mounted) _showProtectionFailed(this.context);
      return;
    }
    if (!context.mounted) return;
    setState(() => _changed = true);
    GlassSnackbar.show(message: l10n.securedToast);
  }

  Future<void> _changePassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();

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
    try {
      await cubit.changePassword(password);
    } catch (_) {
      if (mounted) _showProtectionFailed(this.context);
      return;
    }
    if (!context.mounted) return;
    setState(() => _changed = true);
    GlassSnackbar.show(message: l10n.passwordUpdatedToast);
  }

  Future<void> _removePassword(BuildContext context) async {
    final cubit = context.read<ViewerCubit>();

    final confirmed = await AppDialogs.confirm(
      context,
      title: l10n.removePasswordTitle,
      message: l10n.removePasswordMessage,
      confirmLabel: l10n.removeConfirm,
      cancelLabel: l10n.cancel,
    );
    if (!confirmed || !context.mounted) return;

    await _ensureDecrypted(context, message: l10n.enterCurrentToRemoveMessage);
    if (cubit.state.unlocked == null || !context.mounted) return;

    await Haptics.heavy();
    try {
      await cubit.removePassword();
    } catch (_) {
      if (mounted) _showProtectionFailed(this.context);
      return;
    }
    if (!context.mounted) return;
    setState(() => _changed = true);
    GlassSnackbar.show(message: l10n.protectionRemovedToast);
  }

  void _showProtectionFailed(BuildContext context) {
    GlassSnackbar.show(message: l10n.protectionFailedToast, isError: true);
  }

  Future<void> _ensureDecrypted(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    final cubit = context.read<ViewerCubit>();
    if (!cubit.state.isLocked) return;
    while (cubit.state.unlocked == null) {
      if (!context.mounted) return;
      final password = await showPasswordDialog(
        context,
        title: title ?? l10n.lockedNote,
        message: message ?? l10n.enterCurrentPasswordMessage,
        confirmButtonLabel: l10n.continueLabel,
      );
      if (!context.mounted || password == null) return;
      final ok = await cubit.unlock(password);
      if (!ok && context.mounted) {
        GlassSnackbar.show(message: l10n.wrongPasswordToast, isError: true);
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
