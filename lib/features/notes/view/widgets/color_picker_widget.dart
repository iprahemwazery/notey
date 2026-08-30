import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

class ColorDotWidget extends StatelessWidget {
  const ColorDotWidget({super.key, required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Tooltip(
        message: AppLocalizations.of(context).applyColor,
        child: Container(
          width: 34.w,
          height: 34.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.black26, width: .7),
          ),
        ),
      ),
    );
  }
}
