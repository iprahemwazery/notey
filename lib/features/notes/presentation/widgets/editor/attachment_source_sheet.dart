import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

import 'attachment_sheet_option_widget.dart';

/// Possible sources for inserting a new attachment into the editor.
enum AttachmentSource { camera, gallery, file, voice, draw }

/// Shows the bottom sheet letting the user pick an attachment source.
/// Returns the chosen [AttachmentSource], or null if dismissed.
Future<AttachmentSource?> showAttachmentSourceSheet(BuildContext context) {
  return showModalBottomSheet<AttachmentSource>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.addImageSheetTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 16.h),
              AttachmentSheetOptionWidget(
                icon: Icons.photo_camera_rounded,
                label: l10n.cameraOption,
                onTap: () => Navigator.pop(context, AttachmentSource.camera),
              ),
              SizedBox(height: 8.h),
              AttachmentSheetOptionWidget(
                icon: Icons.photo_library_rounded,
                label: l10n.galleryOption,
                onTap: () => Navigator.pop(context, AttachmentSource.gallery),
              ),
              SizedBox(height: 8.h),
              AttachmentSheetOptionWidget(
                icon: Icons.attach_file_rounded,
                label: l10n.fileFromDeviceOption,
                onTap: () => Navigator.pop(context, AttachmentSource.file),
              ),
              SizedBox(height: 8.h),
              AttachmentSheetOptionWidget(
                icon: Icons.mic_rounded,
                label: l10n.voiceNoteOption,
                onTap: () => Navigator.pop(context, AttachmentSource.voice),
              ),
              SizedBox(height: 8.h),
              AttachmentSheetOptionWidget(
                icon: Icons.draw_rounded,
                label: l10n.drawOption,
                onTap: () => Navigator.pop(context, AttachmentSource.draw),
              ),
            ],
          ),
        ),
      );
    },
  );
}
