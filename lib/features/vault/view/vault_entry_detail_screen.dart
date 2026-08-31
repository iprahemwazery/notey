import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/services/auth_gate.dart';

import 'package:notey/core/services/screen_protector_service.dart';

import 'package:notey/core/services/share_service.dart';

import 'package:notey/data/repositories/secure_vault_repository.dart';

import 'package:notey/features/vault/cubit/vault_cubit.dart';

import 'package:notey/data/services/vault_file_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/features/vault/view/widgets/vault_meta.dart';

import 'package:notey/features/notes/view/drawing_screen.dart';

import 'package:notey/features/notes/view/document_preview_screen.dart';

import 'vault_entry_editor_screen.dart';

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
  final SecureVaultRepository? repository;

  @override
  State<VaultEntryDetailScreen> createState() => _VaultEntryDetailScreenState();
}

class _VaultEntryDetailScreenState extends State<VaultEntryDetailScreen> {
  late VaultEntry _entry = widget.entry;
  final Set<String> _revealed = <String>{'password', 'cvv', 'cardPin'};
  final Set<String> _everRevealed = <String>{};
  late final VaultFileStore _fileStore = VaultFileStore();
  bool _busy = false;

  /// True once the entry was edited (or deleted) so popping reports a change
  /// back to the vault list, which then reloads instead of showing a stale row.
  bool _changed = false;

  /// Flip to true right before a programmatic pop so PopScope lets it through.
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

  String _labelForKey(String key, AppLocalizations l10n) {
    return switch (key) {
      'username' => l10n.vaultFieldUsername,
      'password' => l10n.vaultFieldPassword,
      'cardHolder' => l10n.vaultFieldCardHolder,
      'cardNumber' => l10n.vaultFieldCardNumber,
      'expiry' => l10n.vaultFieldExpiry,
      'cvv' => l10n.vaultFieldCvv,
      'cardPin' => l10n.vaultFieldCardPin,
      'bankName' => l10n.vaultFieldBankName,
      'accountName' => l10n.vaultFieldAccountName,
      'iban' => l10n.vaultFieldIban,
      'swift' => l10n.vaultFieldSwift,
      _ => key,
    };
  }

  Future<void> _copy(String value) async {
    await Haptics.tap();
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.vaultCopiedToast)));
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

      final isDrawing =
          _entry.mediaType == VaultMediaType.drawing ||
          const <String>{
            '.png',
            '.jpg',
            '.jpeg',
            '.webp',
          }.contains(p.extension(temp).toLowerCase());

      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => isDrawing
              ? DrawingScreen(initialPath: temp)
              : DocumentPreviewScreen(path: temp),
        ),
      );
      await VaultFileStore.disposeOf(temp);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaultErrorLoading)));
      }
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
      final refreshed = await (widget.repository ?? SecureVaultRepository())
          .get(_entry.id);
      if (refreshed != null && mounted) {
        setState(() {
          _entry = refreshed;
          _changed = true;
        });
        // Mirror the edit into the vault list immediately.
        _vaultCubit(context)?.applyUpsert(refreshed);
      }
    }
  }

  Future<void> _delete() async {
    await Haptics.tap();
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vaultDeleteTitle),
        content: Text(l10n.vaultDeleteMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final authorized = await AuthGate.require(context);
    if (!authorized || !mounted) return;
    try {
      final repository = widget.repository ?? SecureVaultRepository();
      await repository.delete(_entry.id);
      for (final encPath in _entry.attachments) {
        await _fileStore.delete(encPath);
      }
      if (mounted) {
        _changed = true;
        _vaultCubit(context)?.applyRemove(_entry.id);
        Navigator.pop(context, true);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaultErrorLoading)));
      }
    }
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  /// The vault cubit when this screen was pushed from the vault list.
  VaultCubit? _vaultCubit(BuildContext context) {
    try {
      return context.read<VaultCubit>();
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = VaultMeta.colorFor(_entry.category, scheme);

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
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 28.r,
                      backgroundColor: color.withValues(alpha: .14),
                      child: Icon(
                        VaultMeta.iconFor(_entry.category),
                        color: color,
                        size: 28.w,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Text(
                        _entry.title.isEmpty ? l10n.untitled : _entry.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_entry.fields.isNotEmpty) ...<Widget>[
                  SizedBox(height: 20.h),
                  for (final entry in _entry.fields.entries) ...<Widget>[
                    _SecretFieldRow(
                      label: _labelForKey(entry.key, l10n),
                      value: entry.value,
                      sensitive: _isSensitive(entry.key),
                      revealed:
                          _revealed.contains(entry.key) ||
                          _everRevealed.contains(entry.key),
                      onToggleReveal: () => setState(() {
                        if (_revealed.contains(entry.key)) {
                          _revealed.remove(entry.key);
                        } else {
                          _revealed.add(entry.key);
                          _everRevealed.add(entry.key);
                        }
                      }),
                      onCopy: () => _copy(entry.value),
                    ),
                    SizedBox(height: 10.h),
                  ],
                ],
                if (_entry.notes.isNotEmpty) ...<Widget>[
                  SizedBox(height: 6.h),
                  _SectionCard(
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
                  for (final encPath in _entry.attachments) ...<Widget>[
                    _AttachmentTile(
                      encPath: encPath,
                      onOpen: () => _openAttachment(encPath),
                      onShare: () => _shareFile(encPath),
                    ),
                  ],
                ],
              ],
            ),
      ),
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaultErrorLoading)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.vaultErrorLoading)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _isSensitive(String key) =>
      key == 'password' || key == 'cvv' || key == 'cardPin' || key == 'iban';
}

class _SecretFieldRow extends StatefulWidget {
  const _SecretFieldRow({
    required this.label,
    required this.value,
    required this.sensitive,
    required this.revealed,
    required this.onToggleReveal,
    required this.onCopy,
  });

  final String label;
  final String value;
  final bool sensitive;
  final bool revealed;
  final VoidCallback onToggleReveal;
  final VoidCallback onCopy;

  @override
  State<_SecretFieldRow> createState() => _SecretFieldRowState();
}

class _SecretFieldRowState extends State<_SecretFieldRow> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hidden =
        widget.sensitive && !widget.revealed && widget.value.isNotEmpty;

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 6.w, 6.h),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hidden
                        ? '••••••••'
                        : (widget.value.isEmpty ? '—' : widget.value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.sensitive && widget.value.isNotEmpty)
              IconButton(
                tooltip: hidden ? l10n.vaultShow : l10n.vaultHide,
                onPressed: widget.onToggleReveal,
                icon: Icon(
                  hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            IconButton(
              tooltip: l10n.vaultCopy,
              onPressed: widget.onCopy,
              icon: Icon(Icons.copy_rounded, size: 20.w),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 6.h),
            child,
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({
    required this.encPath,
    required this.onOpen,
    required this.onShare,
  });

  final String encPath;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16.r),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
        leading: const Icon(Icons.lock_rounded),
        title: Text(
          p.basename(encPath),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(l10n.vaultScreenProtected),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: l10n.vaultOpenAttachment,
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
            IconButton(
              tooltip: l10n.vaultShareLabel,
              onPressed: onShare,
              icon: const Icon(Icons.share_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
