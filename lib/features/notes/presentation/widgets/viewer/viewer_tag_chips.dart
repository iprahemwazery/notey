import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A wrap of pill-shaped tag chips. Pure presentation of a tag list.
class ViewerTagChips extends StatelessWidget {
  const ViewerTagChips({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final tag in tags)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: .6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.sell_rounded, size: 13.w, color: scheme.primary),
                SizedBox(width: 5.w),
                Text(
                  tag,
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
