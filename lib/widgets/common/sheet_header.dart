import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// A consistent header row for modal bottom sheets: leading icon, title and a
/// close button. Also exposes the shared rounded-top sheet decoration used by
/// the viewer/editor bottom sheets.
class SheetHeader extends StatelessWidget {
  const SheetHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.onClose,
  });

  final IconData icon;
  final Widget title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, color: scheme.primary),
        SizedBox(width: 10.w),
        Expanded(child: title),
        IconButton(
          tooltip: AppLocalizations.of(context).semCloseSheet,
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

/// The standard rounded-top decoration for the app's bottom sheets.
class RoundedTopSheet {
  RoundedTopSheet._();

  static ShapeBorder shape(ColorScheme scheme) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    );
  }
}
