import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

class BarActionWidget extends StatelessWidget {
  const BarActionWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? scheme.error : scheme.onSurface;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 4.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 22.w, color: color),
              SizedBox(height: 3.h),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionBarWidget extends StatelessWidget {
  const SelectionBarWidget({
    super.key,
    required this.count,
    required this.anyUnpinned,
    required this.onColor,
    required this.onPin,
    required this.onDelete,
  });

  final int count;
  final bool anyUnpinned;
  final VoidCallback onColor;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      minimum: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .18),
              blurRadius: 18.r,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            BarActionWidget(
              icon: Icons.palette_outlined,
              label: l10n.actionColor,
              onTap: onColor,
            ),
            BarActionWidget(
              icon: anyUnpinned
                  ? Icons.push_pin_rounded
                  : Icons.push_pin_outlined,
              label: anyUnpinned ? l10n.actionPin : l10n.actionUnpin,
              onTap: onPin,
            ),
            BarActionWidget(
              icon: Icons.delete_outline_rounded,
              label: l10n.delete,
              danger: true,
              onTap: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
