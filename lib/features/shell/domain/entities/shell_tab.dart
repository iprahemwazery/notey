import 'package:flutter/material.dart';

/// Represents a single navigation tab in the main shell.
///
/// A pure domain entity carrying only in-memory business data.
/// It performs no I/O and no serialization: persistence lives in the
/// data layer (see `ShellLocalDataSource`), never here.
class ShellTab {
  const ShellTab({
    required this.index,
    required this.labelKey,
    required this.icon,
    required this.activeIcon,
  });

  final int index;
  final String labelKey;
  final IconData icon;
  final IconData activeIcon;

  ShellTab copyWith({
    int? index,
    String? labelKey,
    IconData? icon,
    IconData? activeIcon,
  }) {
    return ShellTab(
      index: index ?? this.index,
      labelKey: labelKey ?? this.labelKey,
      icon: icon ?? this.icon,
      activeIcon: activeIcon ?? this.activeIcon,
    );
  }
}
