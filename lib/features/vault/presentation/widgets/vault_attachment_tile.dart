import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as p;

import 'package:notey/l10n/generated/app_localizations.dart';

/// A tile describing one encrypted vault attachment with an open action plus a
/// secondary action (share or remove) supplied by the caller. Used by both the
/// vault detail and editor screens.
class VaultAttachmentTile extends StatelessWidget {
  const VaultAttachmentTile({
    super.key,
    required this.encPath,
    required this.onOpen,
    this.onShare,
    this.onRemove,
  });

  final String encPath;
  final VoidCallback onOpen;
  final VoidCallback? onShare;
  final VoidCallback? onRemove;

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
            if (onShare != null)
              IconButton(
                tooltip: l10n.vaultShareLabel,
                onPressed: onShare,
                icon: const Icon(Icons.share_rounded),
              ),
            if (onRemove != null)
              IconButton(
                tooltip: l10n.delete,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
