import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/theme/theme_extensions.dart';

/// A small primary-colored section heading used across the settings screen.
class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 4.h),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: context.getAdaptiveTextColor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
