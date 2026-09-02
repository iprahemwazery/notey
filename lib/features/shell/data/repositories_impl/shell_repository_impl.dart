import 'package:flutter/material.dart';

import 'package:notey/features/shell/data/datasources/shell_local_data_source.dart';
import 'package:notey/features/shell/domain/entities/shell_tab.dart';
import 'package:notey/features/shell/domain/repositories/shell_repository.dart';
import 'package:notey/l10n/generated/app_localizations.dart';

/// Concrete implementation of [ShellRepository].
///
/// Delegates tab persistence to [ShellLocalDataSource] (SharedPreferences)
/// and provides the static tab configuration with localized labels.
class ShellRepositoryImpl implements ShellRepository {
  ShellRepositoryImpl({ShellLocalDataSource? localDataSource})
      : _local = localDataSource ?? ShellLocalDataSource();

  final ShellLocalDataSource _local;

  @override
  Future<int> getActiveTab() => _local.getActiveTab();

  @override
  Future<void> setActiveTab(int index) => _local.saveActiveTab(index);

  @override
  List<ShellTab> getTabs() {
    return <ShellTab>[
      const ShellTab(
        index: 0,
        labelKey: 'navHome',
        icon: Icons.sticky_note_2_outlined,
        activeIcon: Icons.sticky_note_2_rounded,
      ),
      const ShellTab(
        index: 1,
        labelKey: 'vaultTitle',
        icon: Icons.shield_outlined,
        activeIcon: Icons.shield_rounded,
      ),
      const ShellTab(
        index: 2,
        labelKey: 'trashTitle',
        icon: Icons.delete_outline_rounded,
        activeIcon: Icons.delete_rounded,
      ),
      const ShellTab(
        index: 3,
        labelKey: 'settingsTitle',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
      ),
    ];
  }

  @override
  Future<void> resetToDefault() => _local.clearActiveTab();

  /// Resolves a tab label key to its localized string.
  ///
  /// This is a presentation-layer concern that lives here because the
  /// repository is the single source of truth for tab configuration.
  static String resolveLabel(String labelKey, AppLocalizations l10n) {
    return switch (labelKey) {
      'navHome' => l10n.navHome,
      'vaultTitle' => l10n.vaultTitle,
      'trashTitle' => l10n.trashTitle,
      'settingsTitle' => l10n.settingsTitle,
      _ => labelKey,
    };
  }
}
