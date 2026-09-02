import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The "protection" bottom sheet shown from the viewer app bar: set / change /
/// remove the note password. Pure presentation; the [onSet]/[onChange]/
/// [onRemove] callbacks are wired by the parent.
class ViewerLockMenuSheet extends StatelessWidget {
  const ViewerLockMenuSheet({
    super.key,
    required this.isLocked,
    required this.onSet,
    required this.onChange,
    required this.onRemove,
  });

  final bool isLocked;
  final VoidCallback onSet;
  final VoidCallback onChange;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              isLocked ? l10n.manageProtection : l10n.protectSheetTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 14.h),
            if (!isLocked)
              ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(l10n.setPasswordItem),
                subtitle: Text(l10n.setPasswordSubtitle),
                onTap: onSet,
              )
            else ...<Widget>[
              ListTile(
                leading: const Icon(Icons.password_rounded),
                title: Text(l10n.changePassword),
                onTap: onChange,
              ),
              ListTile(
                leading: Icon(Icons.lock_open_rounded, color: scheme.error),
                title: Text(
                  l10n.removePassword,
                  style: TextStyle(color: scheme.error),
                ),
                onTap: onRemove,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
