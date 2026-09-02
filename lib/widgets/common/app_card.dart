import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A shared, rounded surface container used throughout the app for cards,
/// rows and sections. Centralises the surface-card styling so every screen
/// renders consistent cards without repeating the decoration.

/// The default card radius used by [AppCard] and other shared containers.
const double kAppCardRadius = 16;

/// A generic rounded card on the surface colour (with optional padding).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.radius = kAppCardRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.surfaceContainerLow;
    final card = Material(
      color: effectiveColor,
      borderRadius: BorderRadius.circular(radius.r),
      clipBehavior: Clip.antiAlias,
      child: padding == null
          ? child
          : Padding(padding: padding!, child: child),
    );
    if (onTap == null) return card;
    return InkWell(onTap: onTap, child: card);
  }
}
