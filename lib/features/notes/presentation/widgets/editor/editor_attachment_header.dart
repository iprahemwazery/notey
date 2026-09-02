import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The editor's "attachments" section header: a title with a live count plus
/// an "add attachment" button.
class EditorAttachmentHeader extends StatelessWidget {
  const EditorAttachmentHeader({
    super.key,
    required this.count,
    required this.onAdd,
  });

  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 4.h,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.attachmentsSection,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (count > 0) ...<Widget>[
              SizedBox(width: 4.w),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.attach_file_rounded),
          label: Text(l10n.addAttachment),
        ),
      ],
    );
  }
}
