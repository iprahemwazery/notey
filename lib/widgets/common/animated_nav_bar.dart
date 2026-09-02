import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/theme/theme_extensions.dart';

/// A single destination shown in the [AnimatedNavBar].
class AnimatedNavItem {
  const AnimatedNavItem({
    required this.icon,
    required this.label,
    this.activeIcon,
  });

  final IconData icon;

  /// Optional alternative icon when the tab is active.
  final IconData? activeIcon;

  final String label;
}

/// A reusable, animated bottom navigation bar.
///
/// Active item is animated with a single consistent transition (a springy
/// pill that lifts the icon and reveals the label) so the whole app shares one
/// visual language. Rendering only — tab state lives with the caller.
class AnimatedNavBar extends StatelessWidget {
  const AnimatedNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AnimatedNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 14.h),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(99.r),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .6),
            width: 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: .16),
              blurRadius: 20.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _AnimatedNavItemButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNavItemButton extends StatelessWidget {
  const _AnimatedNavItemButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AnimatedNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        heightFactor: 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 44.h,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: selected ? 10.w : 10.w),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: .14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(99.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              AnimatedScale(
                scale: selected ? 1.12 : 1,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    selected
                        ? (item.activeIcon ?? item.icon)
                        : item.icon,
                    key: ValueKey(selected),
                    size: 22.w,
                    color: color,
                  ),
                ),
              ),
              if (selected)
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(left: 5.w, top: 1.h),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
