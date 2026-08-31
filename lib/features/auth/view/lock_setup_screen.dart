import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/features/auth/cubit/auth_cubit.dart';

import 'package:notey/features/auth/cubit/auth_state.dart';

import 'package:notey/features/notes/cubit/home_cubit.dart';

import 'package:notey/features/notes/view/home_screen.dart';

import 'widgets/backup_pin_setup_view.dart';
import 'widgets/biometric_offer_view.dart';
import 'widgets/choosing_view.dart';
import 'widgets/device_setup_view.dart';
import 'widgets/pin_setup_view.dart';

/// First-run screen: pick the app-lock method.
///
/// Uses [BlocProvider] + [AuthCubit] to manage the multi-step setup flow.
class LockSetupScreen extends StatelessWidget {
  const LockSetupScreen({
    super.key,
    required this.controller,
    required this.biometricService,
    this.repository,
  });

  final AppLockController controller;
  final BiometricService biometricService;
  final NoteRepository? repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        lockController: controller,
        biometricService: biometricService,
      )..init(),
      child: _LockSetupBody(
        controller: controller,
        biometricService: biometricService,
        repository: repository,
      ),
    );
  }
}

class _LockSetupBody extends StatelessWidget {
  const _LockSetupBody({
    required this.controller,
    required this.biometricService,
    this.repository,
  });

  final AppLockController controller;
  final BiometricService biometricService;
  final NoteRepository? repository;

  void _goHome(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(repository ?? NoteRepository()),
          child: HomeScreen(
            repository: repository,
            lockController: controller,
            biometricService: biometricService,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, cur) => cur.phase == AuthPhase.ready,
      listener: (context, state) => _goHome(context),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.phase == AuthPhase.deviceSetup ||
              state.phase == AuthPhase.biometricVerifying) {
            return const DeviceSetupView();
          }
          if (state.phase == AuthPhase.passwordCreate ||
              state.phase == AuthPhase.passwordConfirm) {
            return const PinSetupView();
          }
          if (state.phase == AuthPhase.biometricOffer) {
            return const BiometricOfferView();
          }
          if (state.phase == AuthPhase.backupPinCreate ||
              state.phase == AuthPhase.backupPinConfirm) {
            return const BackupPinSetupView();
          }
          return const ChoosingView();
        },
      ),
    );
  }
}
