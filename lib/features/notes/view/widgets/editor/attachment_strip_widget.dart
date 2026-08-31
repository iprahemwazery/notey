import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/attachment_utils.dart';
import 'package:notey/core/utils/file_icons.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Horizontal strip showing image thumbnails and file chips, with an
/// "add" affordance. Used by the note editor.
class AttachmentStripWidget extends StatelessWidget {
  const AttachmentStripWidget({
    super.key,
    required this.attachments,
    required this.onRemove,
    required this.onAdd,
    required this.onOpenFile,
  });

  final List<String> attachments;
  final ValueChanged<String> onRemove;
  final VoidCallback onAdd;

  /// Opens a non-image attachment with the device's native viewer.
  final ValueChanged<String> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final images = attachments.where(AttachmentUtils.isImage).toList();
    final files = attachments
        .where((a) => !AttachmentUtils.isImage(a))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (images.isNotEmpty)
          SizedBox(
            height: 96.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (final path in images) ...<Widget>[
                  Padding(
                    padding: EdgeInsets.only(left: 10.w),
                    child: Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14.r),
                          child: Image.file(
                            File(path),
                            width: 96.w,
                            height: 96.h,
                            fit: BoxFit.cover,
                            cacheWidth:
                                (96 * MediaQuery.devicePixelRatioOf(context))
                                    .round(),
                            errorBuilder: (_, _, _) => Container(
                              width: 96.w,
                              height: 96.h,
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Semantics(
                            button: true,
                            label: AppLocalizations.of(context).semRemoveImage,
                            child: GestureDetector(
                              onTap: () => onRemove(path),
                              child: Container(
                                padding: EdgeInsets.all(3.w),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: .55),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16.w,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _AddAttachmentTileWidget(
                  onTap: onAdd,
                  icon: Icons.add_a_photo_rounded,
                  label: AppLocalizations.of(context).semAddPhoto,
                ),
              ],
            ),
          )
        else
          _AddAttachmentTileWidget(
            onTap: onAdd,
            icon: Icons.add_a_photo_rounded,
            label: AppLocalizations.of(context).semAddPhoto,
            wide: true,
          ),
        if (files.isNotEmpty) ...<Widget>[
          SizedBox(height: 10.h),
          for (final path in files)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: FileChipWidget(
                path: path,
                onOpen: () => onOpenFile(path),
                onRemove: () => onRemove(path),
              ),
            ),
        ],
      ],
    );
  }
}

/// A rectangular "add" tile shown inside the attachment strip.
class _AddAttachmentTileWidget extends StatelessWidget {
  const _AddAttachmentTileWidget({
    required this.onTap,
    required this.icon,
    required this.label,
    this.wide = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(left: 10.w),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        child: Semantics(
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(14.r),
            onTap: onTap,
            child: SizedBox(
              width: wide ? double.infinity : 96.w,
              height: wide ? 56.h : 96.h,
              child: Icon(icon, color: scheme.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chip representing a non-image file attachment.
class FileChipWidget extends StatelessWidget {
  const FileChipWidget({
    super.key,
    required this.path,
    required this.onOpen,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.semOpenFile,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: onOpen,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(attachmentIcon(path), size: 20.w, color: scheme.primary),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  AttachmentUtils.fileName(path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 6.w),
              Semantics(
                button: true,
                label: l10n.semRemoveFile,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Icon(
                    Icons.close_rounded,
                    size: 18.w,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
            ],
          ),
        ),
      ),
    );
  }
}
