import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/theme/app_theme.dart';

import 'package:notey/features/notes/domain/repositories/note_repository.dart';
import 'package:notey/features/notes/data/repositories_impl/note_repository.dart';

import 'package:notey/features/settings/data/repositories_impl/backup_repository.dart';
import 'package:notey/features/settings/domain/usecases/wipe_all_data.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/auth/presentation/cubits/auth_cubit.dart';

import 'package:notey/features/auth/presentation/cubits/auth_state.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';

import 'package:notey/widgets/pin_widgets.dart';

import 'package:notey/features/notes/presentation/screens/home_screen.dart';


class LockScreen extends StatelessWidget {
  const LockScreen({
    super.key,
    required this.controller,
    required this.biometricService,
    this.repository,
    this.onUnlocked,
  });

  final AppLockController controller;
  final BiometricService biometricService;
  final NoteRepository? repository;
  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(
        lockController: controller,
        biometricService: biometricService,
      )..init(),
      child: _LockBody(
        controller: controller,
        biometricService: biometricService,
        repository: repository,
        onUnlocked: onUnlocked,
      ),
    );
  }
}

class _LockBody extends StatefulWidget {
  const _LockBody({
    required this.controller,
    required this.biometricService,
    this.repository,
    this.onUnlocked,
  });

  final AppLockController controller;
  final BiometricService biometricService;
  final NoteRepository? repository;
  final VoidCallback? onUnlocked;

  @override
  State<_LockBody> createState() => _LockBodyState();
}

class _LockBodyState extends State<_LockBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _goHome() {
    debugPrint('TRACE_3: lock listener triggered navigation to Home');
    if (widget.onUnlocked != null) {
      widget.onUnlocked!();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<HomeCubit>(
          create: (_) => HomeCubit(widget.repository ?? NoteRepositoryImpl()),
          child: HomeScreen(
            repository: widget.repository,
            lockController: widget.controller,
            biometricService: widget.biometricService,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset() async {
    await Haptics.tap();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.resetAppTitle),
        content: Text(l10n.resetAppWarning),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.resetAppConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await WipeAllData(
        BackupRepositoryImpl(lockController: widget.controller),
      )();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (prev, cur) => cur.phase == AuthPhase.ready,
      listener: (_, _) => _goHome(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // App icon
                    Container(
                      width: 72.w,
                      height: 72.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 20.r,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.sticky_note_2_rounded,
                        size: 34.w,
                        color: scheme.primary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      AppConstants.appName,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2.sp,
                          ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      AppLocalizations.of(context).tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    SizedBox(height: 36.h),
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) => Transform.translate(
                        offset: _shakeOffset(),
                        child: child,
                      ),
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(maxWidth: 400.w),
                        padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 24.h),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(28.r),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 30.r,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: BlocConsumer<AuthCubit, AuthState>(
                          listenWhen: (prev, cur) =>
                              cur.error == 'notRecognizedRetry' ||
                              cur.error == 'wrongPin',
                          listener: (context, state) {
                            Haptics.heavy();
                            _shake.forward(from: 0);
                          },
                          builder: (context, state) {
                            final method =
                                state.method ?? AppLockMethod.biometric;
                            return _buildPanel(context, method, state);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel(
    BuildContext context,
    AppLockMethod method,
    AuthState state,
  ) {
    switch (method) {
      case AppLockMethod.pin:
        return _PinPanel(
          state: state,
          onDigit: (d) => context.read<AuthCubit>().onUnlockPinDigit(d),
          onBackspace: () => context.read<AuthCubit>().onUnlockPinBackspace(),
          onReset: _confirmReset,
        );
      case AppLockMethod.biometric:
        return _BiometricPanel(
          state: state,
          onTap: () => context.read<AuthCubit>().authenticateBiometric(),
          onFallback: () => context.read<AuthCubit>().showPinFallback(),
          onDigit: (d) => context.read<AuthCubit>().onUnlockPinDigit(d),
          onBackspace: () => context.read<AuthCubit>().onUnlockPinBackspace(),
          onReset: _confirmReset,
        );
      case AppLockMethod.device:
        return _DevicePanel(
          state: state,
          onTap: () => context.read<AuthCubit>().authenticateDevice(),
          onReset: _confirmReset,
        );
      case AppLockMethod.none:
        return const SizedBox.shrink();
    }
  }

  Offset _shakeOffset() {
    final t = _shake.value;
    if (t < 0.2) return Offset(-10 * (t / 0.2), 0);
    if (t < 0.4) return Offset(10 * ((t - 0.2) / 0.2), 0);
    if (t < 0.6) return Offset(-7 * ((t - 0.4) / 0.2), 0);
    if (t < 0.8) return Offset(5 * ((t - 0.6) / 0.2), 0);
    return Offset.zero;
  }
}

/// ── PIN Panel ──────────────────────
class _PinPanel extends StatelessWidget {
  const _PinPanel({
    required this.state,
    required this.onDigit,
    required this.onBackspace,
    required this.onReset,
  });

  final AuthState state;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locked = state.lockedOut;
    final checking = state.phase == AuthPhase.verifyingPin;

    return Column(
      children: <Widget>[
        Icon(
          Icons.pin_rounded,
          size: 44.w,
          color: locked ? scheme.error : scheme.primary,
        ),
        SizedBox(height: 16.h),
        Text(
          locked
              ? '${l10n.pinLocked} ${state.remainingLockoutSeconds} ${l10n.seconds}'
              : checking
                  ? l10n.verifying
                  : l10n.enterAppPin,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 22.h),
        SizedBox(
          height: 36.h,
          child: PinDots(
            length: 4,
            entered: locked ? 0 : state.pin.length,
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 22.h,
          child: (state.error.isNotEmpty || locked)
              ? Text(
                  locked ? l10n.pinLocked : l10n.wrongPin,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        SizedBox(height: 12.h),
        PinKeypad(
          onDigit: locked ? (_) {} : onDigit,
          onBackspace: locked ? () {} : onBackspace,
        ),
        SizedBox(height: 10.h),
        TextButton(
          onPressed: checking || locked ? null : onReset,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: Text(l10n.forgotPin),
        ),
      ],
    );
  }
}

/// ── Biometric Panel ──────────────────────
class _BiometricPanel extends StatelessWidget {
  const _BiometricPanel({
    required this.state,
    required this.onTap,
    required this.onFallback,
    required this.onDigit,
    required this.onBackspace,
    required this.onReset,
  });

  final AuthState state;
  final VoidCallback onTap;
  final VoidCallback onFallback;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    if (state.phase == AuthPhase.fallbackToPin) {
      return _PinPanel(
        state: state,
        onDigit: onDigit,
        onBackspace: onBackspace,
        onReset: onReset,
      );
    }

    final checking = state.phase == AuthPhase.biometricVerifying;
    return Column(
      children: <Widget>[
        _FingerprintSensor(
          active: checking,
          onTap: onTap,
        ),
        SizedBox(height: 24.h),
        Text(
          checking ? l10n.verifying : l10n.placeFinger,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.biometricBackupHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (state.error.isNotEmpty) ...<Widget>[
          SizedBox(height: 14.h),
          Text(
            l10n.notRecognizedRetry,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: FilledButton.icon(
            onPressed: checking ? null : onTap,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: checking
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(state.error.isNotEmpty ? l10n.retryButton : l10n.tryNowButton),
          ),
        ),
        SizedBox(height: 12.h),
        TextButton.icon(
          onPressed: checking ? null : onFallback,
          style: TextButton.styleFrom(
            foregroundColor: scheme.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          icon: const Icon(Icons.pin_rounded),
          label: Text(l10n.useBackupPin),
        ),
        SizedBox(height: 4.h),
        TextButton(
          onPressed: checking ? null : onReset,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: Text(l10n.forgotPin),
        ),
      ],
    );
  }
}

/// ── Device Panel ──────────────────────
class _DevicePanel extends StatelessWidget {
  const _DevicePanel({
    required this.state,
    required this.onTap,
    required this.onReset,
  });

  final AuthState state;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final checking = state.phase == AuthPhase.biometricVerifying;

    return Column(
      children: <Widget>[
        _FingerprintSensor(
          active: checking,
          onTap: onTap,
        ),
        SizedBox(height: 24.h),
        Text(
          checking ? l10n.verifying : l10n.placeFinger,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8.h),
        Text(
          l10n.deviceCredentialPrimaryHint,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        if (state.error.isNotEmpty) ...<Widget>[
          SizedBox(height: 14.h),
          Text(
            l10n.notRecognizedRetry,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        SizedBox(height: 24.h),
        SizedBox(
          width: double.infinity,
          height: 54.h,
          child: FilledButton.icon(
            onPressed: checking ? null : onTap,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
            ),
            icon: checking
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(
              checking ? l10n.verifying : l10n.tryNowButton,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: checking ? null : onReset,
          style: TextButton.styleFrom(
            foregroundColor: scheme.onSurfaceVariant,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: Text(l10n.forgotPin),
        ),
      ],
    );
  }
}

/// ── Fingerprint Sensor ──────────────────────
class _FingerprintSensor extends StatefulWidget {
  const _FingerprintSensor({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  State<_FingerprintSensor> createState() => _FingerprintSensorState();
}

class _FingerprintSensorState extends State<_FingerprintSensor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, _) {
          final phase = _pulse.value;
          final glowPhase = (phase * 2) % 1;
          return SizedBox(
            width: 164.w,
            height: 164.h,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // Outer glow halo
                Container(
                  width: 150 + 10 * glowPhase,
                  height: 150 + 10 * glowPhase,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        scheme.primary
                            .withValues(alpha: 0.12 + 0.06 * glowPhase),
                        scheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Ripple rings
                for (final delay in const <double>[0, 0.33, 0.66])
                  _ripple(scheme.primary, (phase + delay) % 1),
                // Glass-morphism outer ring
                Container(
                  width: 126.w,
                  height: 126.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.18),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                ),
                // Main gradient sphere
                Container(
                  width: 118.w,
                  height: 118.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[scheme.primary, scheme.tertiary],
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.4),
                        blurRadius: 28.r,
                        spreadRadius: 2.r,
                      ),
                      BoxShadow(
                        color: scheme.tertiary.withValues(alpha: 0.2),
                        blurRadius: 40.r,
                        spreadRadius: 4.r,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: 1 + 0.04 * phase,
                    child: Icon(
                      Icons.fingerprint_rounded,
                      size: 56.w,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Highlight / shine
                Positioned(
                  top: 18,
                  left: 26,
                  child: Container(
                    width: 36.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _ripple(Color color, double t) {
    final size = 118 + 46 * t;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: (1 - t) * 0.4),
          width: 2,
        ),
      ),
    );
  }
}
