import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/theme/theme_extensions.dart';
import 'package:notey/features/notes/presentation/widgets/color_picker_widget.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Shows the bottom sheet for applying a color to multiple selected notes.
Future<void> showBulkColorSheet(
  BuildContext context, {
  required int count,
  required ValueChanged<int> onColor,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.scheme.surfaceContainerHigh,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.colorSheetTitle(count),
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (var i = 0; i < AppConstants.noteColors.length; i++)
                    ColorDotWidget(
                      color: AppConstants.noteColors[i],
                      onTap: () => onColor(i),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
