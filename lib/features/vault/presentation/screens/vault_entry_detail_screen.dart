import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

import 'package:notey/core/services/haptics.dart';
import 'package:notey/core/services/auth_gate.dart';
import 'package:notey/core/services/screen_protector_service.dart';
import 'package:notey/core/services/share_service.dart';
import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/features/vault/presentation/cubits/vault_cubit.dart';
import 'package:notey/data/services/vault_file_store.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';
import 'package:notey/features/vault/domain/usecases/delete_vault_entry.dart';
import 'package:notey/features/vault/domain/usecases/get_vault_entry.dart';
import 'package:notey/features/vault/presentation/widgets/vault_meta.dart';
import 'package:notey/features/notes/presentation/screens/drawing_screen.dart';
import 'package:notey/features/notes/presentation/screens/document_preview_screen.dart';
import 'package:notey/widgets/common/app_dialogs.dart';

import 'vault_entry_editor_screen.dart';
import '../widgets/vault_attachment_tile.dart';
import '../widgets/vault_field_labels.dart';
import '../widgets/vault_secret_field_row.dart';
import '../widgets/vault_section_card.dart';

/// Reads one decrypted vault entry with reveal/hide, copy-to-clipboard,
/// one-tap sharing of the decrypted payload and encrypted attachment viewing.
///
/// While this screen is on screen the OS is asked to block screenshots/screen
/// recording ([ScreenProtectorService.protect]) — restored on dispose.
class VaultEntryDetailScreen extends StatefulWidget {
  const VaultEntryDetailScreen({
    super.key,
    required this.entry,
    this.repository,
  });

  final VaultEntry entry;

  /// Injectable for tests; default repo uses the hardware-backed key.
  final VaultRepository? repository;

  @override
  State<VaultEntryDetailScreen> createState() => _VaultEntryDetailScreenState();
}

class _VaultEntryDetailScreenState extends State<VaultEntryDetailScreen> {
  late VaultEntry _entry = widget.entry;
  final Set<String> _revealed = <String>{'password', 'cvv', 'cardPin'};
  final Set<String> _everRevealed = <String>{};
  late final VaultFileStore _fileStore = VaultFileStore();
  bool _busy = false;
  bool _changed = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    ScreenProtectorService.protect();
  }

  @override
  void dispose() {
    ScreenProtectorService.unprotect();
    super.dispose();
  }

  Future<void> _copy(String value, String key) async {
    await Haptics.tap();
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    GlassSnackbar.show(message: l10n.vaultCopiedToast);
  }

  Future<void> _share() async {
    await Haptics.tap();
    final buffer = StringBuffer()..writeln(_entry.title);
    _entry.fields.forEach((key, value) => buffer.writeln('$key: $value'));
    if (_entry.notes.isNotEmpty) buffer.writeln('\n${_entry.notes}');
    await ShareService.shareText(buffer.toString());
  }

  Future<void> _openAttachment(String encPath) async {
    await Haptics.tap();
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final temp = await _fileStore.decryptToTemp(encPath);
      if (!mounted) {
        await VaultFileStore.disposeOf(temp);
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _previewFor(temp),
        ),
      );
      await VaultFileStore.disposeOf(temp);
    } on Exception {
      if (mounted) GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _previewFor(String temp) {
    final isDrawing =
        _entry.mediaType == VaultMediaType.drawing ||
        const <String>{
          '.png',
          '.jpg',
          '.jpeg',
          '.webp',
        }.contains(p.extension(temp).toLowerCase());
    return isDrawing
        ? DrawingScreen(initialPath: temp)
        : DocumentPreviewScreen(path: temp);
  }

  Future<void> _shareFile(String encPath) async {
    await Haptics.tap();
    if (!mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final temp = await _fileStore.decryptToTemp(encPath);
      final ok = await ShareService.shareFiles(<String>[temp]);
      await VaultFileStore.disposeOf(temp);
      if (!ok && mounted) {
        GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
      }
    } on Exception {
      if (mounted) GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit() async {
    await Haptics.tap();
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultEntryEditorScreen(
          category: _entry.category,
          entry: _entry,
          repository: widget.repository,
        ),
      ),
    );
    if (changed == true && mounted) {
      final refreshed = await GetVaultEntry(
        widget.repository ?? SecureVaultRepository(),
      )(_entry.id);
      if (refreshed != null && mounted) {
        setState(() {
          _entry = refreshed;
          _changed = true;
        });
        _vaultCubit(context)?.applyUpsert(refreshed);
      }
    }
  }

  Future<void> _delete() async {
    await Haptics.tap();
    if (!mounted) return;
    final confirmed = await AppDialogs.confirm(
      context,
      title: l10n.vaultDeleteTitle,
      message: l10n.vaultDeleteMessage,
      confirmLabel: l10n.delete,
      cancelLabel: l10n.cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !mounted) return;
    try {
      final repository = widget.repository ?? SecureVaultRepository();
      await DeleteVaultEntry(repository)(_entry.id);
      for (final encPath in _entry.attachments) {
        await _fileStore.delete(encPath);
      }
      if (mounted) {
        _changed = true;
        _vaultCubit(context)?.applyRemove(_entry.id);
        Navigator.pop(context, true);
      }
    } on Exception {
      if (mounted) GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  VaultCubit? _vaultCubit(BuildContext context) {
    try {
      return context.read<VaultCubit>();
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _canPop = true);
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.vaultTitle),
          actions: <Widget>[
            IconButton(
              tooltip: l10n.vaultShareLabel,
              onPressed: _share,
              icon: const Icon(Icons.share_rounded),
            ),
            IconButton(
              tooltip: l10n.edit,
              onPressed: _edit,
              icon: const Icon(Icons.edit_rounded),
            ),
            IconButton(
              tooltip: l10n.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: scheme.error,
            ),
          ],
        ),
        body: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 40.h),
                children: <Widget>[
                  _VaultHeader(entry: _entry),
                  if (_entry.fields.isNotEmpty)
                    ..._fieldRows(),
                  if (_entry.notes.isNotEmpty) ...<Widget>[
                    SizedBox(height: 6.h),
                    VaultSectionCard(
                      title: l10n.vaultNotes,
                      child: Text(
                        _entry.notes,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                  if (_entry.attachments.isNotEmpty) ...<Widget>[
                    SizedBox(height: 20.h),
                    Text(
                      l10n.vaultAttachmentAdd,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    for (final encPath in _entry.attachments)
                      VaultAttachmentTile(
                        encPath: encPath,
                        onOpen: () => _openAttachment(encPath),
                        onShare: () => _shareFile(encPath),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  List<Widget> _fieldRows() {
    return <Widget>[
      SizedBox(height: 20.h),
      for (final field in _entry.fields.entries) ...<Widget>[
        VaultSecretFieldRow(
          label: vaultFieldLabel(field.key, l10n),
          value: field.value,
          sensitive: isSensitiveVaultField(field.key),
          revealed: _revealed.contains(field.key) ||
              _everRevealed.contains(field.key),
          onToggleReveal: () => setState(() {
            if (_revealed.contains(field.key)) {
              _revealed.remove(field.key);
            } else {
              _revealed.add(field.key);
              _everRevealed.add(field.key);
            }
          }),
          onCopy: () => _copy(field.value, field.key),
        ),
        SizedBox(height: 10.h),
      ],
    ];
  }
}

class _VaultHeader extends StatelessWidget {
  const _VaultHeader({required this.entry});

  final VaultEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = VaultMeta.colorFor(entry.category, Theme.of(context).colorScheme);
    final l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 28.r,
          backgroundColor: color.withValues(alpha: .14),
          child: Icon(
            VaultMeta.iconFor(entry.category),
            color: color,
            size: 28.w,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            entry.title.isEmpty ? l10n.untitled : entry.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
