import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Full-width gradient save button used at the bottom of the note editor.
class GradientSaveButtonWidget extends StatelessWidget {
  const GradientSaveButtonWidget({
    super.key,
    required this.onPressed,
    required this.saving,
  });

  final VoidCallback? onPressed;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[scheme.primary, scheme.tertiary],
    );

    return Material(
      color: Colors.transparent,
      child: Ink(
        width: double.infinity,
        height: 56.h,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(alpha: .4),
              blurRadius: 18.r,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Semantics(
          button: true,
          label: l10n.semSaveNote,
          hint: l10n.semSaveNoteHint,
          child: InkWell(
            borderRadius: BorderRadius.circular(18.r),
            onTap: onPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (saving)
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.save_rounded, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  saving ? l10n.saving : l10n.editorSaveButton,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
