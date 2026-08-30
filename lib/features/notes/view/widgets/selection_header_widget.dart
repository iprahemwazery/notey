import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

class SelectionHeaderWidget extends StatelessWidget {
  const SelectionHeaderWidget({
    super.key,
    required this.count,
    required this.totalCount,
    required this.onSelectAll,
    required this.onClose,
  });

  final int count;
  final int totalCount;
  final VoidCallback onSelectAll;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: .35),
              blurRadius: 14.r,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            IconButton(
              tooltip: AppLocalizations.of(context).selectionClear,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: scheme.onPrimary),
            ),
            Expanded(
              child: Text(
                AppLocalizations.of(context).selectionCount(count, totalCount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: count == totalCount
                  ? AppLocalizations.of(context).selectionNone
                  : AppLocalizations.of(context).selectionAll,
              onPressed: onSelectAll,
              icon: Icon(
                count == totalCount
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
