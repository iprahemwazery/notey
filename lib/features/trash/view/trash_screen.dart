import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/auth_gate.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/reminder_service.dart';

import 'package:notey/core/services/ui_prefs.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/data/services/image_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note.dart';


/// Trash bin: notes stay here for [retentionDays] days before being purged.
/// From here a note can be restored or deleted forever (frees its images).
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
  List<Note> _notes = const <Note>[];
  bool _loading = true;
  int _retentionDays = UiPrefs.defaultRetentionDays;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _retentionDays = await UiPrefs.trashRetentionDays();
    // Auto-purge notes past the retention window before showing the list.
    final expired = await widget.repository.purgeExpired(
      Duration(days: _retentionDays),
    );
    await ReminderService.cancelAll(expired.map((n) => n.id));
    for (final note in expired) {
      await _deleteImages(note);
    }
    if (!mounted) return;
    final notes = await widget.repository.getDeletedNotes();
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _loading = false;
    });
  }

  Future<void> _deleteImages(Note note) async {
    for (final path in note.attachments) {
      await widget.imageStore.delete(path);
    }
  }

  Future<void> _restore(Note note) async {
    Haptics.tap();
    await widget.repository.restore(note.id);
    unawaited(ReminderService.sync(note));
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).restoredToast(_displayTitle(note)),
        ),
      ),
    );
  }

  Future<void> _purgeForever(Note note) async {
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
    if (confirmed != true || !mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !mounted) return;
    await Haptics.heavy();
    await widget.repository.purge(note.id);
    await ReminderService.cancel(note.id);
    await _deleteImages(note);
    await _load();
  }

  Future<void> _emptyTrash() async {
    if (_notes.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.emptyTrashTitle),
        content: Text(l10n.emptyTrashMessage(_notes.length)),
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
    if (confirmed != true || !mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !mounted) return;
    await Haptics.heavy();
    final trashed = await widget.repository.emptyTrash();
    await ReminderService.cancelAll(trashed.map((n) => n.id));
    for (final note in trashed) {
      await _deleteImages(note);
    }
    await _load();
  }

  String _displayTitle(Note note) {
    final l10n = AppLocalizations.of(context);
    if (note.isLocked) return l10n.lockedNote;
    final title = note.title.trim();
    return title.isEmpty ? l10n.untitled : title;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

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
            IconButton(
              tooltip: l10n.emptyTrashTooltip,
              onPressed: _notes.isEmpty ? null : _emptyTrash,
              icon: const Icon(Icons.delete_sweep_outlined),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _notes.isEmpty
            ? Center(
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
                        l10n.trashRetentionLabel(_retentionDays),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                itemCount: _notes.length,
                itemBuilder: (context, index) {
                  final note = _notes[index];
                  final background =
                      AppConstants.noteColors[note.colorIndex %
                          AppConstants.noteColors.length];
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
                          ? const Icon(Icons.lock_rounded)
                          : Icon(
                              Icons.sticky_note_2_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      title: Text(
                        _displayTitle(note),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: note.deletedAt == null
                          ? null
                          : Text(_relativeDays(note.deletedAt!)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            tooltip: l10n.restoreTooltip,
                            icon: const Icon(Icons.restore_rounded),
                            onPressed: () => _restore(note),
                          ),
                          IconButton(
                            tooltip: l10n.purgeForeverTooltip,
                            icon: Icon(
                              Icons.delete_forever_rounded,
                              color: scheme.error,
                            ),
                            onPressed: () => _purgeForever(note),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _relativeDays(DateTime deletedAt) {
    final l10n = AppLocalizations.of(context);
    final days = DateTime.now().difference(deletedAt).inDays;
    if (days <= 0) return l10n.deletedToday;
    if (days == 1) return l10n.deletedYesterday;
    return l10n.deletedDaysAgo(days);
  }
}
