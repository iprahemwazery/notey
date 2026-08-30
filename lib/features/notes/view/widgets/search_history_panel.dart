import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Compact panel showing recent search terms as chips under the search field.
/// Each chip re-runs the search when tapped and can be removed with its X.
class SearchHistoryPanel extends StatelessWidget {
  const SearchHistoryPanel({
    super.key,
    required this.history,
    required this.onSelected,
    required this.onRemove,
    required this.onClear,
  });

  final List<String> history;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: scheme.surfaceContainerLow.withValues(alpha: .75),
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 8.w, 10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.history_rounded,
                  size: 17.w,
                  color: scheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    l10n.searchHistoryTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                  ),
                  child: Text(l10n.searchHistoryClear),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: <Widget>[
                for (final term in history)
                  InputChip(
                    avatar: Icon(
                      Icons.search_rounded,
                      size: 15.w,
                      color: scheme.primary,
                    ),
                    label: Text(
                      term,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                    deleteIcon: Icon(
                      Icons.close_rounded,
                      size: 15.w,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => onSelected(term),
                    onDeleted: () => onRemove(term),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
