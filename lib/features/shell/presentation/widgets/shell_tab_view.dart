import 'package:flutter/material.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/data/services/image_store.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/presentation/screens/home_screen.dart';
import 'package:notey/features/settings/presentation/screens/settings_screen.dart';
import 'package:notey/features/trash/presentation/screens/trash_screen.dart';
import 'package:notey/features/vault/presentation/screens/vault_screen.dart';

/// Builds the screen for a given shell tab index.
///
/// Tabs are built lazily (a tab's widget is only inserted once first
/// visited) and then kept alive, so switching tabs preserves each screen's
/// state without eagerly constructing Vault/Settings (which would hit
/// platform I/O at startup).
class ShellTabView extends StatelessWidget {
  const ShellTabView({
    super.key,
    required this.index,
    required this.repository,
    required this.lockController,
    required this.biometricService,
    required this.imageStore,
    required this.onOpenDestination,
  });

  final int index;
  final NoteRepository repository;
  final AppLockController lockController;
  final BiometricService biometricService;
  final ImageStore imageStore;
  final ValueChanged<int> onOpenDestination;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => HomeScreen(
          repository: repository,
          lockController: lockController,
          biometricService: biometricService,
          imageStore: imageStore,
          onOpenDestination: onOpenDestination,
        ),
      1 => const VaultScreen(),
      2 => TrashScreen(repository: repository, imageStore: imageStore),
      3 => SettingsScreen(
          repository: repository,
          lockController: lockController,
          biometricService: biometricService,
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
