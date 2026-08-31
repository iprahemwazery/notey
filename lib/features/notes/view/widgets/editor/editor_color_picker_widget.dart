import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';
import 'package:notey/core/utils/color_utils.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Horizontal color palette picker used in the note editor.
class EditorColorPickerWidget extends StatelessWidget {
  const EditorColorPickerWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: <Widget>[
        Icon(
          Icons.palette_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: List<Widget>.generate(
              AppConstants.noteColors.length,
              (index) {
                final color = AppConstants.noteColors[index];
                final selected = index == selectedIndex;
                final onColor = ColorUtils.foregroundOn(color);
                return Semantics(
                  button: true,
                  label: l10n.semSelectColor(
                    color.toARGB32().toRadixString(16),
                  ),
                  child: GestureDetector(
                    onTap: () => onSelected(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 34.w,
                      height: 34.h,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? onColor : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: onColor.withValues(alpha: .35),
                                  blurRadius: 8.r,
                                ),
                              ]
                            : null,
                      ),
                      child: selected
                          ? Icon(
                              Icons.check_rounded,
                              size: 18.w,
                              color: onColor,
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
