import 'package:flutter/material.dart';

import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/domain/usecases/get_all_notes_including_deleted.dart';
import 'package:notey/features/notes/domain/usecases/insert_notes.dart';
import 'package:notey/features/settings/data/repositories_impl/backup_repository.dart';
import 'package:notey/features/settings/domain/repositories/backup_repository.dart';
import 'package:notey/features/settings/domain/usecases/export_backup.dart';
import 'package:notey/features/settings/domain/usecases/import_backup.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'settings_section.dart';

class BackupSection extends StatefulWidget {
  BackupSection({
    super.key,
    required this.repository,
    BackupRepository? backupRepository,
  }) : backupRepository = backupRepository ?? BackupRepositoryImpl();

  final NoteRepository repository;
  final BackupRepository backupRepository;

  @override
  State<BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<BackupSection> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = context.getAdaptiveTextColor(context);
    final mutedColor = context.getAdaptiveMutedTextColor(context);
    return Column(
      children: <Widget>[
        SettingsSectionLabel(text: l10n.sectionBackup),
        ListTile(
          leading: Icon(Icons.file_upload_outlined, color: textColor),
          title: Text(
            l10n.exportNotes,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
          subtitle: Text(
            l10n.exportSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          onTap: _busy ? null : _exportBackup,
        ),
        ListTile(
          leading: Icon(Icons.file_download_outlined, color: textColor),
          title: Text(
            l10n.importBackup,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: textColor),
          ),
          subtitle: Text(
            l10n.importSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          onTap: _busy ? null : _importBackup,
        ),
      ],
    );
  }

  Future<void> _exportBackup() async {
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final notes = await GetAllNotesIncludingDeleted(widget.repository)();
      if (!mounted) return;
      if (notes.isEmpty) {
        GlassSnackbar.show(
          message: AppLocalizations.of(context).noNotesToExport,
        );
        return;
      }
      await ExportBackup(widget.backupRepository)(notes);
    } on Exception {
      if (mounted) {
        GlassSnackbar.show(
          message: AppLocalizations.of(context).exportFailed,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final notes = await ImportBackup(widget.backupRepository)();
    if (notes == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.importConfirmTitle),
          content: Text(l10n.importConfirmMessage(notes.length)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.importConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await InsertNotes(widget.repository)(notes);
      if (!mounted) return;
      GlassSnackbar.show(
        message: AppLocalizations.of(context).importedToast(notes.length),
      );
    } on FormatException {
      if (mounted) {
        GlassSnackbar.show(
          message: AppLocalizations.of(context).invalidBackupFile,
          isError: true,
        );
      }
    } on Exception {
      if (mounted) {
        GlassSnackbar.show(
          message: AppLocalizations.of(context).readFileFailed,
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}