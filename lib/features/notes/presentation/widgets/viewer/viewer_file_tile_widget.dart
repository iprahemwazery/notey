import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/attachment_utils.dart';
import 'package:notey/core/utils/file_icons.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A tappable file attachment tile with a share action, used in the viewer.
class ViewerFileTileWidget extends StatelessWidget {
  const ViewerFileTileWidget({
    super.key,
    required this.path,
    required this.onOpen,
    required this.onShare,
  });

  final String path;
  final VoidCallback onOpen;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14.r),
        child: Semantics(
          button: true,
          label:
              '${AppLocalizations.of(context).semOpenFile} ${AttachmentUtils.fileName(path)}',
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onOpen,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: <Widget>[
                  Icon(attachmentIcon(path), size: 22.w, color: scheme.primary),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      AttachmentUtils.fileName(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    tooltip: AppLocalizations.of(context).shareTooltip,
                    onPressed: onShare,
                    icon: Icon(Icons.ios_share_rounded, size: 20.w),
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
