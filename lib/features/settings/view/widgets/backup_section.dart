import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:notey/core/services/backup_service.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/data/repositories/note_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'settings_section.dart';

class BackupSection extends StatefulWidget {
  const BackupSection({super.key, required this.repository});

  final NoteRepository repository;

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
      final notes = await widget.repository.getAllNotesIncludingDeleted();
      if (!mounted) return;
      if (notes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).noNotesToExport)),
        );
        return;
      }
      final file = await BackupService.exportNotes(notes);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)]),
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).exportFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importBackup() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
    );
    final path = files.isEmpty ? null : files.single.path;
    if (path == null || !mounted) return;

    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final notes = await BackupService.parseBackup(path);
      if (!mounted) return;
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
      await widget.repository.insertAll(notes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).importedToast(notes.length),
          ),
        ),
      );
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).invalidBackupFile),
          ),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).readFileFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}