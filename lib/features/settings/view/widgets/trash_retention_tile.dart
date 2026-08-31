import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/ui_prefs.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// A tile that lets the user choose how long deleted notes stay in the trash.
class TrashRetentionTile extends StatefulWidget {
  const TrashRetentionTile({super.key});

  @override
  State<TrashRetentionTile> createState() => _TrashRetentionTileState();
}

class _TrashRetentionTileState extends State<TrashRetentionTile> {
  int _days = UiPrefs.defaultRetentionDays;

  @override
  void initState() {
    super.initState();
    UiPrefs.trashRetentionDays().then((v) {
      if (mounted) setState(() => _days = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textColor = context.getAdaptiveTextColor(context);
    final mutedColor = context.getAdaptiveMutedTextColor(context);
    return ListTile(
      leading: Icon(Icons.delete_outline_rounded, color: textColor),
      title: Text(
        l10n.trashRetention,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
      subtitle: Text(
        l10n.trashRetentionDays(_days),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: mutedColor),
      ),
      trailing: Icon(Icons.chevron_left_rounded, color: mutedColor),
      onTap: _pickRetention,
    );
  }

  Future<void> _pickRetention() async {
    final l10n = AppLocalizations.of(context);
    final textColor = context.getAdaptiveTextColor(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        final current = _days;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 16.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (final d in <int>[7, 14, 30]) ...<Widget>[
                  ListTile(
                    leading: Icon(
                      Icons.calendar_today_rounded,
                      color: textColor,
                    ),
                    title: Text(
                      l10n.trashRetentionDays(d),
                      style: Theme.of(sheetContext).textTheme.bodyLarge
                          ?.copyWith(color: textColor),
                    ),
                    trailing: d == current
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: context.getAdaptiveMutedTextColor(context),
                          ),
                    onTap: () => Navigator.pop(sheetContext, d),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && picked != _days) {
      await UiPrefs.setTrashRetentionDays(picked);
      if (mounted) setState(() => _days = picked);
    }
  }
}
