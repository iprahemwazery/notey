import 'package:flutter/material.dart';

import 'package:notey/core/theme/theme_extensions.dart';

/// A single selectable theme-mode option (System / Light / Dark) shown in the
/// appearance section of the settings screen.
class ThemeTile extends StatelessWidget {
  const ThemeTile({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = context.getAdaptiveTextColor(context);
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        leading: Icon(icon, color: selected ? scheme.primary : titleColor),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: scheme.primary)
            : Icon(
                Icons.radio_button_unchecked_rounded,
                color: context.getAdaptiveMutedTextColor(context),
              ),
        onTap: onTap,
      ),
    );
  }
}
