import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

import 'vault_attachment_tile.dart';

/// The vault editor's attachment section: add/draw chips when empty, or a list
/// of attachments with open/remove actions plus add/draw buttons.
class VaultAttachmentList extends StatelessWidget {
  const VaultAttachmentList({
    super.key,
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
          VaultAttachmentTile(
            encPath: attachments[i],
            onOpen: () => onOpen(attachments[i]),
            onRemove: () => onRemove(i),
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
