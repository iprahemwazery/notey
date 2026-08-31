import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/checklist.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Renders note content as an interactive checklist of task lines.
///
/// [onColor] / [mutedOnColor] are the readable tones over the note's fill
/// color so checklist items stay legible on light and deep note colors.
class ViewerTaskListWidget extends StatelessWidget {
  const ViewerTaskListWidget({
    super.key,
    required this.content,
    required this.fontScale,
    required this.onToggle,
    required this.onColor,
    required this.mutedOnColor,
  });

  final String content;
  final double fontScale;
  final ValueChanged<int> onToggle;
  final Color onColor;
  final Color mutedOnColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lines = content.split('\n');

    final children = <Widget>[];
    var taskIndex = -1;
    for (final line in lines) {
      if (Checklist.isTaskLine(line)) {
        taskIndex++;
        final index = taskIndex;
        final checked = line.toLowerCase().contains('[x]');
        final text =
            line.replaceFirst(RegExp(r'^\s*-\s\[[ xX]\]\s?'), '');
        final hasText = text.trim().isNotEmpty;
        children.add(
          Semantics(
            checked: checked,
            label: hasText
                ? text
                : AppLocalizations.of(context).semChecklistItem,
            hint: AppLocalizations.of(context).semChecklistHint,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onToggle(index),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 3.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      checked
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 22.w,
                      color: checked
                          ? scheme.primary
                          : mutedOnColor,
                    ),
                    if (hasText) ...<Widget>[
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                            fontSize: 16 * fontScale,
                            color: mutedOnColor,
                            decoration: checked ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        children.add(SizedBox(height: 8.h));
      } else {
        children.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Text(
              line,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.7, color: onColor),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
