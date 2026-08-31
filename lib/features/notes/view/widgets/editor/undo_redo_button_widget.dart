import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A compact undo/redo icon button whose enabled state dims the icon.
class UndoRedoButtonWidget extends StatelessWidget {
  const UndoRedoButtonWidget({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(
        icon,
        size: 20.w,
        color: enabled
            ? scheme.onSurfaceVariant
            : scheme.onSurfaceVariant.withValues(alpha: .3),
      ),
    );
  }
}
