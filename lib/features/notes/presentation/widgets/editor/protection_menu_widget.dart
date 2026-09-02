import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// AppBar action toggling the note's password protection.
class ProtectionMenuWidget extends StatelessWidget {
  const ProtectionMenuWidget({
    super.key,
    required this.protected,
    required this.canRemove,
    required this.onSelect,
  });

  final bool protected;
  final bool canRemove;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: AppLocalizations.of(context).protectMenuTooltip,
      enabled: onSelect != null,
      onSelected: onSelect,
      icon: Icon(
        protected ? Icons.lock_rounded : Icons.lock_open_rounded,
        color: protected ? scheme.primary : null,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      itemBuilder: (context) {
        final l10n = AppLocalizations.of(context);
        return <PopupMenuEntry<String>>[
          if (!protected)
            PopupMenuItem<String>(
              value: 'set',
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(l10n.setPasswordItem),
                dense: true,
              ),
            )
          else ...<PopupMenuEntry<String>>[
            if (canRemove)
              PopupMenuItem<String>(
                value: 'remove',
                child: ListTile(
                  leading: Icon(
                    Icons.lock_open_rounded,
                    color: scheme.error,
                  ),
                  title: Text(l10n.removePasswordOnSave),
                  dense: true,
                ),
              )
            else
              PopupMenuItem<String>(
                value: 'keep',
                enabled: false,
                child: ListTile(
                  leading: const Icon(Icons.lock_rounded),
                  title: Text(l10n.noteProtectedItem),
                  dense: true,
                ),
              ),
          ],
        ];
      },
    );
  }
}
