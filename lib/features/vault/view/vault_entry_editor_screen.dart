import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

import 'package:notey/core/services/haptics.dart';

import 'package:notey/data/repositories/secure_vault_repository.dart';

import 'package:notey/data/services/vault_file_store.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/features/notes/view/drawing_screen.dart';

import 'package:notey/features/notes/view/document_preview_screen.dart';


/// Form screen describing one vault entry. Fields are generated per category
/// (logins, credit cards, bank accounts, secure notes), and any attachments
/// are sealed through [VaultFileStore] before being referenced.
class VaultEntryEditorScreen extends StatefulWidget {
  const VaultEntryEditorScreen({
    super.key,
    required this.category,
    this.entry,
    this.repository,
  });

  final VaultCategory category;
  final VaultEntry? entry;

  /// Injectable for tests; defaults to the real secure-storage-backed repo.
  final SecureVaultRepository? repository;

  @override
  State<VaultEntryEditorScreen> createState() => _VaultEntryEditorScreenState();
}

class _FieldSpec {
  const _FieldSpec(this.label, this.obscure);

  final String label;
  final bool obscure;
}

class _VaultEntryEditorScreenState extends State<VaultEntryEditorScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.entry?.title ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.entry?.notes ?? '',
  );
  final List<TextEditingController> _fields = <TextEditingController>[];
  late final List<_FieldSpec> _specs = _specsFor(widget.category);
  VaultMediaType _mediaType = VaultMediaType.none;
  List<String> _attachments = <String>[];
  bool _saving = false;
  late final VaultFileStore _fileStore = VaultFileStore();

  final _random = Random.secure();

  List<_FieldSpec> _specsFor(VaultCategory category) {
    return switch (category) {
      VaultCategory.login => const <_FieldSpec>[
        _FieldSpec('username', false),
        _FieldSpec('password', true),
      ],
      VaultCategory.creditCard => const <_FieldSpec>[
        _FieldSpec('cardHolder', false),
        _FieldSpec('cardNumber', false),
        _FieldSpec('expiry', false),
        _FieldSpec('cvv', true),
        _FieldSpec('cardPin', true),
      ],
      VaultCategory.bankAccount => const <_FieldSpec>[
        _FieldSpec('bankName', false),
        _FieldSpec('accountName', false),
        _FieldSpec('iban', false),
        _FieldSpec('swift', false),
      ],
      VaultCategory.secureNote => const <_FieldSpec>[],
    };
  }

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _mediaType = entry?.mediaType ?? VaultMediaType.none;
    _attachments = List<String>.of(entry?.attachments ?? const <String>[]);
    for (final spec in _specs) {
      final value = entry?.fields[spec.label] ?? '';
      _fields.add(TextEditingController(text: value));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    for (final controller in _fields) {
      controller.dispose();
    }
    super.dispose();
  }

  String _labelFor(String key, AppLocalizations l10n) {
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

  Future<void> _attach() async {
    await Haptics.tap();
    if (!mounted) return;
    final picked = await FilePicker.pickFiles(type: FileType.any);
    final path = picked.isEmpty ? null : picked.single.path;
    if (path == null || !mounted) return;
    if (_saving) return;

    setState(() => _saving = true);
    try {
      final encPath = await _fileStore.persistEncrypted(path);
      if (!mounted) return;
      setState(() {
        _attachments = <String>[..._attachments, encPath];
        if (_mediaType == VaultMediaType.none) {
          _mediaType = VaultMediaType.infer(<String>[path]);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.vaultAttachmentHint} (${p.basename(path)})'),
          duration: const Duration(seconds: 2),
        ),
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.documentOpenFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _draw() async {
    await Haptics.tap();
    if (!mounted || _saving) return;

    final drawPath = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        fullscreenDialog: true,
        builder: (_) => const DrawingScreen(),
      ),
    );
    if (drawPath == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final encPath = await _fileStore.persistEncrypted(drawPath);
      if (!mounted) return;
      setState(() {
        _attachments = <String>[..._attachments, encPath];
        _mediaType = VaultMediaType.drawing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.vaultAttachmentHint} (${p.basename(drawPath)})',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.documentOpenFailed)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _title.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vaultTitleLabel)));
      return;
    }

    setState(() => _saving = true);
    final fields = <String, String>{};
    for (var i = 0; i < _specs.length; i++) {
      final value = _fields[i].text.trim();
      if (value.isNotEmpty) fields[_specs[i].label] = value;
    }

    final existing = widget.entry;
    final now = DateTime.now();
    final mediaType = _mediaType == VaultMediaType.none
        ? VaultMediaType.infer(_attachments)
        : _mediaType;

    final entry = VaultEntry(
      id: existing?.id ?? VaultEntry.newId(),
      category: widget.category,
      title: title,
      fields: fields,
      notes: _notes.text.trim(),
      mediaType: mediaType,
      attachments: _attachments,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final repository =
          widget.repository ??
          SecureVaultRepository(); // Fresh repo: vault screen reloads on return.
      await repository.upsert(entry);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.vaultErrorLoading)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? l10n.vaultAdd : l10n.edit),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.save,
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
              children: <Widget>[
                TextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.vaultTitleLabel,
                    hintText: l10n.vaultTitleHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
                for (var i = 0; i < _specs.length; i++) ...<Widget>[
                  SizedBox(height: 14.h),
                  _FieldRow(
                    controller: _fields[i],
                    label: _labelFor(_specs[i].label, l10n),
                    obscure: _specs[i].obscure,
                    allowGenerate: _specs[i].label == 'password',
                    onGenerate: () =>
                        setState(() => _fields[i].text = _generate()),
                  ),
                ],
                if (widget.category == VaultCategory.secureNote ||
                    _specs.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  TextField(
                    controller: _notes,
                    maxLines: widget.category == VaultCategory.secureNote
                        ? 6
                        : 4,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      labelText: l10n.vaultNotes,
                      hintText: l10n.vaultNotesHint,
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20.h),
                Text(
                  l10n.vaultAttachmentAdd,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8.h),
                _AttachmentList(
                  attachments: _attachments,
                  onAdd: _attach,
                  onDraw: _draw,
                  onOpen: _openAttachment,
                  onRemove: _removeAttachment,
                ),
                if (_attachments.isNotEmpty) ...<Widget>[
                  SizedBox(height: 16.h),
                  Text(
                    l10n.vaultMediaLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  SegmentedButton<VaultMediaType>(
                    segments: <ButtonSegment<VaultMediaType>>[
                      ButtonSegment<VaultMediaType>(
                        value: VaultMediaType.none,
                        label: Text(l10n.vaultMediaAuto),
                      ),
                      ButtonSegment<VaultMediaType>(
                        value: VaultMediaType.document,
                        label: Text(l10n.vaultMediaDocument),
                      ),
                      ButtonSegment<VaultMediaType>(
                        value: VaultMediaType.audio,
                        label: Text(l10n.vaultMediaAudio),
                      ),
                      ButtonSegment<VaultMediaType>(
                        value: VaultMediaType.drawing,
                        label: Text(l10n.vaultMediaDrawing),
                      ),
                    ],
                    selected: <VaultMediaType>{_mediaType},
                    onSelectionChanged: (selection) {
                      setState(() => _mediaType = selection.first);
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Future<void> _openAttachment(String encPath) async {
    await Haptics.tap();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      final temp = await _fileStore.decryptToTemp(encPath);
      if (!mounted) {
        await VaultFileStore.disposeOf(temp);
        return;
      }
      final isDrawing =
          _mediaType == VaultMediaType.drawing ||
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
    }
  }

  Future<void> _removeAttachment(int index) async {
    await Haptics.tap();
    final target = _attachments[index];
    await _fileStore.delete(target);
    if (!mounted) return;
    setState(() {
      _attachments = <String>[
        ..._attachments.take(index),
        ..._attachments.skip(index + 1),
      ];
      if (_attachments.isEmpty) _mediaType = VaultMediaType.none;
    });
  }

  AppLocalizations get l10n => AppLocalizations.of(context);

  String _generate() {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const symbols = '!@#\$%^&*()-_=+';
    final pool = letters + digits + symbols;
    final buffer = StringBuffer();
    for (var i = 0; i < 20; i++) {
      buffer.write(pool[_random.nextInt(pool.length)]);
    }
    return buffer.toString();
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onGenerate,
    required this.allowGenerate,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onGenerate;
  final bool allowGenerate;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    String? generateLabel;
    if (allowGenerate) generateLabel = localizations.vaultGeneratePassword;
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r)),
        suffixIcon: allowGenerate
            ? IconButton(
                tooltip: generateLabel,
                onPressed: onGenerate,
                icon: const Icon(Icons.refresh_rounded),
              )
            : null,
      ),
    );
  }
}

class _AttachmentList extends StatelessWidget {
  const _AttachmentList({
    required this.attachments,
    required this.onAdd,
    required this.onDraw,
    required this.onOpen,
    required this.onRemove,
  });

  final List<String> attachments;
  final VoidCallback onAdd;
  final VoidCallback onDraw;
  final ValueChanged<String> onOpen;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (attachments.isEmpty) {
      return Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: <Widget>[
          ActionChip(
            avatar: Icon(Icons.lock_rounded, size: 18.w),
            label: Text(l10n.vaultAttachmentAdd),
            onPressed: onAdd,
          ),
          ActionChip(
            avatar: Icon(Icons.draw_rounded, size: 18.w),
            label: Text(l10n.drawOption),
            onPressed: onDraw,
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        for (var i = 0; i < attachments.length; i++) ...<Widget>[
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.lock_rounded),
            title: Text(
              p.basename(attachments[i]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(l10n.vaultScreenProtected),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: l10n.vaultOpenAttachment,
                  onPressed: () => onOpen(attachments[i]),
                  icon: const Icon(Icons.open_in_new_rounded),
                ),
                IconButton(
                  tooltip: l10n.delete,
                  onPressed: () => onRemove(i),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        ],
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: <Widget>[
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.vaultAttachmentAdd),
            ),
            TextButton.icon(
              onPressed: onDraw,
              icon: const Icon(Icons.draw_rounded),
              label: Text(l10n.drawOption),
            ),
          ],
        ),
      ],
    );
  }
}
