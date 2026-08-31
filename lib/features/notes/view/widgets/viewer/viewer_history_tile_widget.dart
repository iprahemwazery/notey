import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/arabic_date_time.dart';
import 'package:notey/features/notes/model/note_history.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A single edit-history entry tile used in the viewer history sheet.
class ViewerHistoryTileWidget extends StatelessWidget {
  const ViewerHistoryTileWidget({
    super.key,
    required this.entry,
    required this.isCurrent,
    required this.onTap,
  });

  final NoteHistory entry;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final preview = entry.content.trim();
    final previewText =
        preview.length > 80 ? '${preview.substring(0, 80)}...' : preview;

    return ListTile(
      leading: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: isCurrent
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            entry.title.isNotEmpty ? entry.title[0] : '?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isCurrent ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: 18.sp,
            ),
          ),
        ),
      ),
      title: Text(
        entry.title.isNotEmpty ? entry.title : l10n.untitled,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isCurrent ? scheme.primary : null,
        ),
      ),
      subtitle: previewText.isNotEmpty
          ? Text(
              previewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            ArabicDateTime.full(entry.timestamp, l10n: l10n),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (isCurrent) ...<Widget>[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                l10n.currentVersion,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
