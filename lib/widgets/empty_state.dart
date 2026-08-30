import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Friendly empty state shown when there are no notes.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 110.w,
              height: 110.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[scheme.primary, scheme.tertiary],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: .3),
                    blurRadius: 30.r,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.sticky_note_2_outlined,
                size: 52.w,
                color: scheme.onPrimary,
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              isSearching ? l10n.noResults : l10n.emptyNotes,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 8.h),
            Text(
              isSearching ? l10n.tryOtherSearch : l10n.emptyNotesHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
