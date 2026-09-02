import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/arabic_date_time.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Reminder row with a toggle switch and edit/clear actions in the editor.
class ReminderRowWidget extends StatelessWidget {
  const ReminderRowWidget({
    super.key,
    required this.reminderAt,
    required this.onPick,
    required this.onClear,
  });

  final DateTime? reminderAt;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final has = reminderAt != null;

    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(14.w, 10.h, 8.w, 10.h),
      decoration: BoxDecoration(
        color: has
            ? scheme.primaryContainer.withValues(alpha: .35)
            : scheme.surfaceContainerHigh.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: has ? scheme.primary.withValues(alpha: .4) : Colors.transparent,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.alarm_rounded,
            size: 20.w,
            color: has ? scheme.primary : scheme.onSurfaceVariant,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.reminderSection,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  has
                      ? ArabicDateTime.full(reminderAt!, l10n: l10n)
                      : l10n.noReminder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: has ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: has,
            onChanged: (_) {
              if (has) {
                onClear();
              } else {
                onPick();
              }
            },
          ),
          IconButton(
            tooltip: l10n.editReminder,
            onPressed: onPick,
            icon: Icon(
              has ? Icons.edit_calendar_rounded : Icons.add_alarm_rounded,
            ),
          ),
          if (has)
            IconButton(
              tooltip: l10n.clearReminder,
              onPressed: onClear,
              icon: Icon(Icons.close_rounded, color: scheme.error),
            ),
        ],
      ),
    );
  }
}
