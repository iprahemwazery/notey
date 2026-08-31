import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/utils/checklist.dart';
import 'package:notey/core/utils/color_utils.dart';
import 'package:notey/core/utils/markdown.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

import 'highlighted_text_widget.dart';
import 'viewer_task_list_widget.dart';

/// The colored card presenting a note's title and its renderable content
/// (plain text, highlighted search results, checklist, or markdown).
///
/// [background] is the note's actual fill color; the readable text/border
/// tones are derived from it with [ColorUtils] so light and deep note colors
/// both stay legible (the card is filled with [background], never with the
/// derived foreground).
class NoteContentCardWidget extends StatelessWidget {
  const NoteContentCardWidget({
    super.key,
    required this.noteId,
    required this.pinned,
    required this.locked,
    required this.title,
    required this.content,
    required this.background,
    required this.highlightQuery,
    required this.highlightColor,
    required this.fontScale,
    required this.onToggleTask,
  });

  final String noteId;
  final bool pinned;
  final bool locked;
  final String title;
  final String content;
  final Color background;
  final String highlightQuery;
  final Color highlightColor;
  final double fontScale;
  final ValueChanged<int>? onToggleTask;

  @override
  Widget build(BuildContext context) {
    final highlightActive = highlightQuery.isNotEmpty;
    final onColor = ColorUtils.foregroundOn(background);
    final mutedOnColor = ColorUtils.foregroundMutedOn(background);
    final TextStyle? bodyStyle =
        Theme.of(context).textTheme.bodyLarge?.copyWith(
          height: 1.7,
          color: mutedOnColor,
        );

    Widget? body;
    if (locked) {
      body = const SizedBox.shrink();
    } else if (highlightActive) {
      body = HighlightedTextWidget(
        text: content.isEmpty
            ? AppLocalizations.of(context).noDetails
            : content,
        query: highlightQuery,
        style: bodyStyle,
        highlightColor: highlightColor,
      );
    } else if (Checklist.hasTasks(content)) {
      body = ViewerTaskListWidget(
        content: content,
        fontScale: fontScale,
        onToggle: onToggleTask ?? (_) {},
        onColor: onColor,
        mutedOnColor: mutedOnColor,
      );
    } else if (content.isEmpty) {
      body = Text(
        AppLocalizations.of(context).noDetails,
        style: bodyStyle,
      );
    } else {
      body = MarkdownText(
        data: content,
        fontSize: 16 * fontScale,
        color: mutedOnColor,
      );
    }

    return Hero(
      tag: 'note-bg-$noteId',
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(22.r),
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: onColor.withValues(alpha: .25)),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    if (pinned) ...<Widget>[
                      Icon(
                        Icons.push_pin_rounded,
                        size: 18.w,
                        color: Color(0xFFE08600),
                      ),
                      SizedBox(width: 6.w),
                    ],
                    if (locked) ...<Widget>[
                      Icon(
                        Icons.lock_rounded,
                        size: 18.w,
                        color: onColor,
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: onColor,
                            ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
