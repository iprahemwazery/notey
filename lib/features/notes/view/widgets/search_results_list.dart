import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/utils/arabic_date_time.dart';

import 'package:notey/core/utils/color_utils.dart';

import 'package:notey/core/utils/file_icons.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/notes/model/note_search_result.dart';


/// WhatsApp-style advanced-search results: every hit is its own row with the
/// note title on top, the matched snippet below, and a divider between rows.
class SearchResultsList extends StatelessWidget {
  const SearchResultsList({
    super.key,
    required this.results,
    required this.query,
    required this.onTap,
  });

  final List<NoteSearchMatch> results;
  final String query;
  final ValueChanged<NoteSearchMatch> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 6.h),
          child: Text(
            l10n.searchResultsCount(results.length),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(0.w, 0.h, 0.w, 110.h),
            itemCount: results.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              thickness: .7,
              indent: 68.w,
              endIndent: 12.w,
              color: scheme.outlineVariant.withValues(alpha: .45),
            ),
            itemBuilder: (context, index) {
              final result = results[index];
              return _SearchResultTile(
                result: result,
                query: query,
                onTap: () => onTap(result),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  final NoteSearchMatch result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final note = result.note;
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = AppConstants
        .noteColors[note.colorIndex % AppConstants.noteColors.length];
    final iconBg = isDark
        ? Color.lerp(baseColor, const Color(0xFF171A21), .55)!
        : baseColor;
    final iconColor = ColorUtils.foregroundOn(iconBg);
    final locked = note.isLocked;
    final displayTitle = locked
        ? l10n.lockedNote
        : (note.title.isEmpty ? l10n.untitled : note.title);

    final leadingIcon = result.matchedInFile
        ? attachmentIcon(result.fileName ?? '')
        : result.matchedInTitle
        ? Icons.title_rounded
        : Icons.notes_rounded;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Icon(leadingIcon, size: 20.w, color: iconColor),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      if (locked) ...<Widget>[
                        Icon(
                          Icons.lock_rounded,
                          size: 12.w,
                          color: scheme.onSurfaceVariant,
                        ),
                        SizedBox(width: 3.w),
                      ],
                      Expanded(
                        child: _HighlightedText(
                          text: displayTitle,
                          query: locked ? '' : query,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          highlightColor: scheme.primary,
                        ),
                      ),
                      Text(
                        ArabicDateTime.relative(note.updatedAt, l10n: l10n),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10.sp,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  if (result.matchedInFile)
                    Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.attach_file_rounded,
                            size: 11.w,
                            color: scheme.primary,
                          ),
                          SizedBox(width: 3.w),
                          Flexible(
                            child: Text(
                              result.fileName ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (result.preview.isNotEmpty)
                    _HighlightedText(
                      text: result.preview,
                      query: query,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11.5.sp,
                        height: 1.4,
                        color: scheme.onSurfaceVariant,
                      ),
                      highlightColor: scheme.primary,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20.w,
              color: scheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders [text] with every (case-insensitive) occurrence of [query]
/// emphasized with the app primary color.
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightColor,
  });

  final String text;
  final String query;
  final TextStyle? style;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: style);

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    var start = 0;
    while (start <= lower.length) {
      final idx = lower.indexOf(qLower, start);
      if (idx < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: style));
      }
      spans.add(
        TextSpan(
          text: text.substring(idx, idx + query.length),
          style: style?.copyWith(
            color: highlightColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = idx + query.length;
    }
    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
