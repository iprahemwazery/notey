import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

import 'package:notey/core/services/haptics.dart';
import 'package:notey/core/widgets/note_snackbar.dart';
import 'package:notey/features/vault/data/repositories_impl/secure_vault_repository.dart';
import 'package:notey/features/vault/presentation/cubits/vault_cubit.dart';
import 'package:notey/data/services/vault_file_store.dart';
import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/domain/entities/vault_entry.dart';
import 'package:notey/features/vault/domain/repositories/vault_repository.dart';
import 'package:notey/features/vault/domain/usecases/save_vault_entry.dart';
import 'package:notey/features/notes/presentation/screens/drawing_screen.dart';
import 'package:notey/features/notes/presentation/screens/document_preview_screen.dart';
import 'package:notey/widgets/common/app_text_field.dart';

import '../widgets/vault_attachment_list.dart';
import '../widgets/vault_field_labels.dart';
import '../widgets/vault_field_row.dart';
import '../widgets/vault_form_model.dart';

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
  final VaultRepository? repository;

  @override
  State<VaultEntryEditorScreen> createState() => _VaultEntryEditorScreenState();
}

class _VaultEntryEditorScreenState extends State<VaultEntryEditorScreen> {
  late final TextEditingController _title = TextEditingController(
    text: widget.entry?.title ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.entry?.notes ?? '',
  );
  final List<TextEditingController> _fields = <TextEditingController>[];
  late final List<VaultFieldSpec> _specs =
      VaultFormModel.specsFor(widget.category);
  VaultMediaType _mediaType = VaultMediaType.none;
  List<String> _attachments = <String>[];
  bool _saving = false;
  late final VaultFileStore _fileStore = VaultFileStore();

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _mediaType = entry?.mediaType ?? VaultMediaType.none;
    _attachments = List<String>.of(entry?.attachments ?? const <String>[]);
    for (final spec in _specs) {
      final value = entry?.fields[spec.key] ?? '';
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

  Future<void> _attach() async {
    await Haptics.tap();
    if (!mounted || _saving) return;
    final picked = await FilePicker.pickFiles(type: FileType.any);
    final path = picked.isEmpty ? null : picked.single.path;
    if (path == null || !mounted) return;
    await _sealAttachment(path);
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
    await _sealAttachment(drawPath, drawing: true);
  }

  Future<void> _sealAttachment(String path, {bool drawing = false}) async {
    setState(() => _saving = true);
    try {
      final encPath = await _fileStore.persistEncrypted(path);
      if (!mounted) return;
      setState(() {
        _attachments = <String>[..._attachments, encPath];
        if (drawing) {
          _mediaType = VaultMediaType.drawing;
        } else if (_mediaType == VaultMediaType.none) {
          _mediaType = VaultMediaType.infer(<String>[path]);
        }
      });
      GlassSnackbar.show(message: '${l10n.vaultAttachmentHint} (${p.basename(path)})');
    } on Exception {
      if (mounted) GlassSnackbar.show(message: l10n.documentOpenFailed, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      GlassSnackbar.show(message: l10n.vaultTitleLabel, isError: true);
      return;
    }

    setState(() => _saving = true);
    final fields = <String, String>{};
    for (var i = 0; i < _specs.length; i++) {
      final value = _fields[i].text.trim();
      if (value.isNotEmpty) fields[_specs[i].key] = value;
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
      final cubit = _vaultCubit(context);
      if (cubit != null) {
        await cubit.upsert(entry);
      } else {
        await SaveVaultEntry(repository)(entry);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on Exception {
      if (!mounted) return;
      setState(() => _saving = false);
      GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
    }
  }

  Future<void> _openAttachment(String encPath) async {
    await Haptics.tap();
    if (!mounted) return;
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
      if (mounted) GlassSnackbar.show(message: l10n.vaultErrorLoading, isError: true);
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

  VaultCubit? _vaultCubit(BuildContext context) {
    try {
      return context.read<VaultCubit>();
    } on Object {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                AppTextField(
                  controller: _title,
                  textInputAction: TextInputAction.next,
                  labelText: l10n.vaultTitleLabel,
                  hintText: l10n.vaultTitleHint,
                ),
                for (var i = 0; i < _specs.length; i++) ...<Widget>[
                  SizedBox(height: 14.h),
                  VaultFieldRow(
                    controller: _fields[i],
                    label: vaultFieldLabel(_specs[i].key, l10n),
                    obscure: _specs[i].obscure,
                    onGenerate: _specs[i].canGenerate
                        ? () => setState(() {
                              _fields[i].text = VaultFormModel.generatePassword();
                            })
                        : null,
                  ),
                ],
                if (widget.category == VaultCategory.secureNote ||
                    _specs.isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  AppTextField(
                    controller: _notes,
                    maxLines: widget.category == VaultCategory.secureNote ? 6 : 4,
                    textAlignVertical: TextAlignVertical.top,
                    labelText: l10n.vaultNotes,
                    hintText: l10n.vaultNotesHint,
                    alignLabelWithHint: true,
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
                VaultAttachmentList(
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
}
