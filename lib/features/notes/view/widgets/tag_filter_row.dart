import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

class TagFilterRow extends StatelessWidget {
  const TagFilterRow({
    super.key,
    required this.tags,
    required this.activeTag,
    required this.onSelected,
  });

  final List<String> tags;
  final String? activeTag;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    Widget chip(String label, {required bool selected, VoidCallback? onTap}) {
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8.w),
        child: Semantics(
          selected: selected,
          label: label,
          child: ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => onTap?.call(),
            visualDensity: VisualDensity.compact,
            showCheckmark: false,
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
            selectedColor: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .6)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 42.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
        children: <Widget>[
          chip(
            l10n.allTags,
            selected: activeTag == null,
            onTap: () => onSelected(null),
          ),
          for (final tag in tags)
            chip(
              '#$tag',
              selected: activeTag == tag,
              onTap: () => onSelected(tag),
            ),
        ],
      ),
    );
  }
}
