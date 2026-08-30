import 'package:flutter/material.dart';

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
    return Semantics(
      selected: selected,
      button: true,
      child: ListTile(
        leading: Icon(icon, color: selected ? scheme.primary : null),
        title: Text(title),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: scheme.primary)
            : const Icon(Icons.radio_button_unchecked_rounded),
        onTap: onTap,
      ),
    );
  }
}
