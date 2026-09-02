import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/core/services/app_lock_controller.dart';
import 'package:notey/core/services/biometric_service.dart';
import 'package:notey/data/services/image_store.dart';
import 'package:notey/features/notes/domain/repositories/note_repository.dart';

import 'package:notey/features/shell/data/repositories_impl/shell_repository_impl.dart';
import 'package:notey/features/shell/domain/entities/shell_tab.dart';
import 'package:notey/features/shell/domain/repositories/shell_repository.dart';
import 'package:notey/features/shell/presentation/cubits/shell_cubit.dart';
import 'package:notey/features/shell/presentation/cubits/shell_state.dart';
import 'package:notey/features/shell/presentation/widgets/double_back_exit_handler.dart';
import 'package:notey/features/shell/presentation/widgets/lazy_indexed_stack.dart';
import 'package:notey/features/shell/presentation/widgets/shell_tab_view.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

import 'package:notey/widgets/common/animated_nav_bar.dart';

/// The app's main shell: hosts the primary destinations (Home, Vault, Trash,
/// Settings) behind a single reusable [AnimatedNavBar].
///
/// Navigation state (active tab, visited tabs, tab config) is owned by
/// [ShellCubit]. Tabs are built lazily (a tab's widget is only inserted once
/// first visited) and then kept alive, so switching tabs preserves each
/// screen's state without eagerly constructing Vault/Settings (which would
/// hit platform I/O at startup).
class MainShell extends StatelessWidget {
  MainShell({
    super.key,
    required this.repository,
    required this.lockController,
    required this.biometricService,
    ImageStore? imageStore,
    ShellRepository? shellRepository,
  }) : imageStore = imageStore ?? ImageStore(),
       shellRepository = shellRepository ?? ShellRepositoryImpl();

  final NoteRepository repository;
  final AppLockController lockController;
  final BiometricService biometricService;

  /// Injectable for tests; defaults to a real [ImageStore].
  final ImageStore imageStore;

  /// Injectable for tests; defaults to a real [ShellRepositoryImpl].
  final ShellRepository shellRepository;

  String _labelFor(ShellTab tab, AppLocalizations l10n) {
    final label = ShellRepositoryImpl.resolveLabel(tab.labelKey, l10n);
    return label.isEmpty ? tab.labelKey : label;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider<ShellCubit>(
      create: (_) => ShellCubit(shellRepository)..init(),
      child: BlocBuilder<ShellCubit, ShellState>(
        builder: (context, state) {
          final items = <AnimatedNavItem>[
            for (final tab in state.tabs)
              AnimatedNavItem(
                icon: tab.icon,
                activeIcon: tab.activeIcon,
                label: _labelFor(tab, l10n),
              ),
          ];

          final tabs = <Widget>[
            for (final tab in state.tabs)
              ShellTabView(
                index: tab.index,
                repository: repository,
                lockController: lockController,
                biometricService: biometricService,
                imageStore: imageStore,
                onOpenDestination: (index) =>
                    context.read<ShellCubit>().selectTab(index),
              ),
          ];

          return DoubleBackExitHandler(
            child: Scaffold(
              body: LazyIndexedStack(
                index: state.activeTabIndex,
                visited: state.visitedTabs,
                children: tabs,
              ),
              bottomNavigationBar: AnimatedNavBar(
                items: items,
                currentIndex: state.activeTabIndex,
                onTap: (index) =>
                    context.read<ShellCubit>().selectTab(index),
              ),
            ),
          );
        },
      ),
    );
  }
}
