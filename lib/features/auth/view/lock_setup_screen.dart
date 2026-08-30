import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/theme/app_theme.dart';

import 'package:notey/data/repositories/note_repository.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/auth/cubit/auth_cubit.dart';

import 'package:notey/features/auth/cubit/auth_state.dart';

import 'package:notey/features/notes/cubit/home_cubit.dart';

import 'package:notey/widgets/pin_widgets.dart';

import 'package:notey/features/notes/view/home_screen.dart';


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
            return _DeviceSetupView(controller: controller);
          }
          if (state.phase == AuthPhase.passwordCreate ||
              state.phase == AuthPhase.passwordConfirm) {
            return _PinSetupView();
          }
          if (state.phase == AuthPhase.biometricOffer) {
            return _BiometricOfferView();
          }
          if (state.phase == AuthPhase.backupPinCreate ||
              state.phase == AuthPhase.backupPinConfirm) {
            return _BackupPinSetupView();
          }
          // choosing or initial
          return _ChoosingView(controller: controller);
        },
      ),
    );
  }
}

/// ── Choosing View: Two beautiful cards ──────────────────────
class _ChoosingView extends StatelessWidget {
  const _ChoosingView({required this.controller});

  final AppLockController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 520
                  ? 520.0
                  : constraints.maxWidth;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 24.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Logo
                        Container(
                          width: 80.w,
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16),
                                blurRadius: 24.r,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_outline_rounded,
                            size: 38.w,
                            color: scheme.primary,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          l10n.welcomeTitle(AppConstants.appName),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.chooseLockSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                height: 1.5,
                              ),
                        ),
                        SizedBox(height: 18.h),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: <Widget>[
                            _BenefitChip(
                              icon: Icons.shield_rounded,
                              label: isArabic ? 'أمان' : 'Secure',
                            ),
                            _BenefitChip(
                              icon: Icons.speed_rounded,
                              label: isArabic ? 'سرعة' : 'Fast',
                            ),
                            _BenefitChip(
                              icon: Icons.backup_rounded,
                              label: isArabic ? 'نسخ احتياطي' : 'Backup',
                            ),
                          ],
                        ),
                        SizedBox(height: 28.h),
                        _AuthOptionCard(
                          icon: Icons.phone_iphone_rounded,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.8),
                            ],
                          ),
                          title: l10n.lockOptionDeviceTitle,
                          subtitle: l10n.lockOptionDeviceSubtitle,
                          recommended: true,
                          onTap: () => context.read<AuthCubit>().chooseDevice(),
                        ),
                        SizedBox(height: 16.h),
                        _AuthOptionCard(
                          icon: Icons.password_rounded,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              scheme.tertiary,
                              scheme.tertiary.withValues(alpha: 0.8),
                            ],
                          ),
                          title: l10n.lockOptionPasswordTitle,
                          subtitle: l10n.lockOptionPasswordSubtitle,
                          onTap: () =>
                              context.read<AuthCubit>().choosePassword(),
                        ),
                        SizedBox(height: 20.h),
                        _SecurityFooter(),
                        SizedBox(height: 12.h),
                        _RecommendedHint(),
                        SizedBox(height: 12.h),
                        _WhyThisMatters(),
                        SizedBox(height: 18.h),
                        TextButton(
                          onPressed: () =>
                              context.read<AuthCubit>().chooseSkip(),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white.withValues(
                              alpha: 0.8,
                            ),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.sp,
                            ),
                          ),
                          child: Text(l10n.lockOptionSkip),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// ── Auth Option Card ──────────────────────
class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14.w, color: Colors.white),
          SizedBox(width: 6.w),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.privacy_tip_rounded,
            size: 18.w,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              isArabic
                  ? 'ملاحظاتك تبقى خاصة على الجهاز مع خيارات حماية متقدمة.'
                  : 'Your notes stay private on this device with advanced protection.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedHint extends StatelessWidget {
  const _RecommendedHint();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999.r),
        ),
        child: Text(
          isArabic ? 'الأفضل: قفل الجهاز' : 'Best for most users: Device lock',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WhyThisMatters extends StatelessWidget {
  const _WhyThisMatters();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(999.r),
        onTap: () {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(isArabic ? 'لماذا قفل الجهاز؟' : 'Why device lock?'),
              content: Text(
                isArabic
                    ? 'قفل الجهاز يعتمد على قفل هاتفك نفسه؛ لذلك يضمن وصولًا أسرع وأمانًا أعلى، ويقلل الحاجة إلى حفظ رقم سري إضافي في التطبيق.'
                    : 'Device lock uses your phone’s secure unlock to keep notes private with minimal friction and a simpler setup flow.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(isArabic ? 'حسنًا' : 'Okay'),
                ),
              ],
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.info_outline_rounded,
                size: 14.w,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              SizedBox(width: 6.w),
              Text(
                isArabic ? 'لماذا هذا الأفضل؟' : 'Why this is recommended?',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthOptionCard extends StatelessWidget {
  const _AuthOptionCard({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.recommended = false,
    required this.onTap,
  });

  final IconData icon;
  final Gradient gradient;
  final String title;
  final String subtitle;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(24.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 56.w,
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12.r,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 28.w),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (recommended)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isArabic ? 'موصى به' : 'Recommended',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.6),
                size: 18.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Device Setup View ──────────────────────
class _DeviceSetupView extends StatelessWidget {
  const _DeviceSetupView({required this.controller});

  final AppLockController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
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
                child: BlocBuilder<AuthCubit, AuthState>(
                  buildWhen: (p, c) => p.phase != c.phase || p.error != c.error,
                  builder: (context, state) {
                    if (state.phase == AuthPhase.biometricVerifying) {
                      return Column(
                        children: <Widget>[
                          SizedBox(
                            width: 48.w,
                            height: 48.h,
                            child: const CircularProgressIndicator(),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            l10n.verifying,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: <Widget>[
                        Container(
                          width: 72.w,
                          height: 72.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[scheme.primary, scheme.tertiary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.phone_iphone_rounded,
                            size: 34.w,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          l10n.deviceSetupTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          l10n.deviceSetupBody,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                        ),
                        SizedBox(height: 24.h),
                        if (state.error.isNotEmpty) ...<Widget>[
                          Text(
                            state.error,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 12.h),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 54.h,
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.read<AuthCubit>().authenticateDevice(),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: Text(l10n.tryNowButton),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              context.read<AuthCubit>().goBackToChoosing();
                            },
                            child: Text(l10n.chooseAnotherMethod),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ── PIN Setup View ──────────────────────
class _PinSetupView extends StatefulWidget {
  @override
  State<_PinSetupView> createState() => _PinSetupViewState();
}

class _PinSetupViewState extends State<_PinSetupView> {
  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final confirming = state.phase == AuthPhase.passwordConfirm;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
                          Icons.lock_outline_rounded,
                          size: 34.w,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        confirming ? l10n.pinConfirmTitle : l10n.pinCreateTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        confirming
                            ? l10n.pinReenterPrompt
                            : l10n.pinEnterLength(_pinLength),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      SizedBox(height: 36.h),
                      Container(
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
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: 36.h,
                              child: PinDots(
                                length: _pinLength,
                                entered: state.pin.length,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            SizedBox(
                              height: 24.h,
                              child: state.error.isNotEmpty
                                  ? Text(
                                      state.error == 'pinMismatchError'
                                          ? l10n.pinMismatchError
                                          : state.error,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.error,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    )
                                  : null,
                            ),
                            SizedBox(height: 16.h),
                            PinKeypad(
                              onDigit: (d) =>
                                  context.read<AuthCubit>().onPinDigit(d),
                              onBackspace: () =>
                                  context.read<AuthCubit>().onPinBackspace(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                      TextButton(
                        onPressed: () {
                          context.read<AuthCubit>().goBackToChoosing();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withValues(alpha: 0.8),
                        ),
                        child: Text(l10n.chooseAnotherMethod),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ── Biometric Offer View ──────────────────────
class _BiometricOfferView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
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
                child: Column(
                  children: <Widget>[
                    // Fingerprint icon with glow
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[scheme.primary, scheme.tertiary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.35),
                            blurRadius: 24.r,
                            spreadRadius: 2.r,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 40.w,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      l10n.biometricOfferTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.biometricOfferBody(AppConstants.appName),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: scheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.info_outline_rounded,
                            size: 18.w,
                            color: scheme.tertiary,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              l10n.biometricBackupNotice,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: scheme.onTertiaryContainer,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: FilledButton.icon(
                        onPressed: () =>
                            context.read<AuthCubit>().acceptBiometric(),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: Text(l10n.enableBiometric),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () =>
                            context.read<AuthCubit>().skipBiometric(),
                        child: Text(l10n.skipBiometric),
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
}

/// ── Backup PIN Setup View ──────────────────────
class _BackupPinSetupView extends StatelessWidget {
  static const int _pinLength = 4;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final confirming = state.phase == AuthPhase.backupPinConfirm;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
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
                          Icons.pin_rounded,
                          size: 34.w,
                          color: scheme.primary,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        confirming ? l10n.pinConfirmTitle : l10n.pinBackupTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        confirming ? l10n.pinReenterPrompt : l10n.backupPinBody,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      SizedBox(height: 36.h),
                      Container(
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
                        child: Column(
                          children: <Widget>[
                            SizedBox(
                              height: 36.h,
                              child: PinDots(
                                length: _pinLength,
                                entered: state.backupPin.length,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            SizedBox(
                              height: 24.h,
                              child: state.error.isNotEmpty
                                  ? Text(
                                      state.error == 'pinMismatchError'
                                          ? l10n.pinMismatchError
                                          : state.error,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.error,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    )
                                  : null,
                            ),
                            SizedBox(height: 16.h),
                            PinKeypad(
                              onDigit: (d) =>
                                  context.read<AuthCubit>().onPinDigit(d),
                              onBackspace: () =>
                                  context.read<AuthCubit>().onPinBackspace(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Standalone screen for changing the app PIN (used from settings).
class PinChangeScreen extends StatefulWidget {
  const PinChangeScreen({super.key, required this.controller});

  final AppLockController controller;

  @override
  State<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends State<PinChangeScreen> {
  static const int _pinLength = 4;
  String _entered = '';
  String? _firstEntry;
  String _error = '';

  void _onDigit(String d) {
    if (_entered.length >= _pinLength) return;
    setState(() {
      _entered += d;
      _error = '';
    });
    if (_entered.length == _pinLength) {
      Future.delayed(const Duration(milliseconds: 160), _onEntered);
    }
  }

  Future<void> _onEntered() async {
    await Haptics.light();
    if (!mounted) return;
    if (_firstEntry == null) {
      setState(() {
        _firstEntry = _entered;
        _entered = '';
      });
      return;
    }
    if (_entered != _firstEntry) {
      await Haptics.heavy();
      if (!mounted) return;
      setState(() {
        _entered = '';
        _firstEntry = null;
        _error = AppLocalizations.of(context).pinMismatchError;
      });
      return;
    }
    await widget.controller.setPin(_entered);
    if (mounted) Navigator.of(context).pop(true);
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final confirming = _firstEntry != null;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(confirming ? l10n.pinConfirmTitle : l10n.changePin),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth > 520
                ? 520.0
                : constraints.maxWidth;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 28.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(height: 24.h),
                      Container(
                        width: 64.w,
                        height: 64.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[scheme.primary, scheme.tertiary],
                          ),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 30.w,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        confirming
                            ? l10n.pinReenterPrompt
                            : l10n.pinEnterLength(_pinLength),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 24.h),
                      SizedBox(
                        height: 36.h,
                        child: PinDots(
                          length: _pinLength,
                          entered: _entered.length,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 22.h,
                        child: _error.isEmpty
                            ? null
                            : Text(
                                _error,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                      ),
                      SizedBox(height: 24.h),
                      PinKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
