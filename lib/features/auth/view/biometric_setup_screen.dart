import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/constants/app_constants.dart';

import 'package:notey/core/services/app_lock_controller.dart';

import 'package:notey/core/services/biometric_service.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/core/theme/app_theme.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// Guides the user through enabling fingerprint/face unlock.
///
/// If no fingerprint is enrolled on the device, the app explains how to
/// register one and opens the device's biometric settings when asked.
/// Fingerprints never leave the device — the app only asks the OS sensor
/// to verify the enrolled fingerprint.
class BiometricSetupScreen extends StatefulWidget {
  const BiometricSetupScreen({
    super.key,
    required this.controller,
    required this.biometricService,
  });

  final AppLockController controller;
  final BiometricService biometricService;

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  BiometricAvailability? _availability;
  bool _checking = true;
  bool _busy = false;
  String _notice = '';

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final availability = await widget.biometricService.getAvailability();
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _checking = false;
      _notice = '';
    });
  }

  Future<void> _openSettings() async {
    await Haptics.tap();
    if (!mounted) return;
    final opened = await widget.biometricService.openBiometricsSettings();
    if (!mounted) return;
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).cannotOpenSettings),
        ),
      );
    }
  }

  Future<void> _enable() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _notice = '';
    });
    final result = await widget.biometricService.authenticate(
      localizedReason: AppLocalizations.of(context).biometricPrompt,
    );
    if (!mounted) return;
    if (result == BiometricResult.authenticated) {
      if (!mounted) return;
      // PIN creation is now handled by AuthCubit in the setup flow.
      // Simply complete this screen.
      await widget.controller.setMethod(AppLockMethod.biometric);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      final l10n = AppLocalizations.of(context);
      _notice = result == BiometricResult.unavailable
          ? l10n.bioUnavailableNow
          : l10n.bioNotRecognizedLong;
    });
  }

  Future<void> _confirmedEnrolled() async {
    await Haptics.tap();
    if (!mounted) return;
    setState(() {
      _checking = true;
      _notice = '';
    });
    final availability = await widget.biometricService.getAvailability();
    if (!mounted) return;
    setState(() {
      _availability = availability;
      _checking = false;
      if (availability == BiometricAvailability.noneEnrolled) {
        _notice = AppLocalizations.of(context).bioNotYetNotice;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                      color: Colors.black.withValues(alpha: .22),
                      blurRadius: 30.r,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: _checking
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 48.h),
                        child: Column(
                          children: <Widget>[
                            const CircularProgressIndicator(),
                            SizedBox(height: 16.h),
                            Text(
                              AppLocalizations.of(context).bioCheckingSensor,
                            ),
                          ],
                        ),
                      )
                    : _buildContent(scheme),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme scheme) {
    switch (_availability) {
      case BiometricAvailability.unsupported:
        return _UnsupportedBody(onBack: () => Navigator.of(context).pop());
      case BiometricAvailability.noneEnrolled:
        return _EnrollGuideBody(
          notice: _notice,
          busy: _checking,
          onOpenSettings: _openSettings,
          onConfirmed: _confirmedEnrolled,
        );
      default:
        return _ReadyBody(
          busy: _busy,
          notice: _notice,
          onEnable: _enable,
          onBack: () => Navigator.of(context).pop(),
        );
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 30.w,
          height: 30.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[scheme.primary, scheme.tertiary],
            ),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.primary.withValues(alpha: .25),
                blurRadius: 8.r,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13.sp,
            ),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnrollGuideBody extends StatelessWidget {
  const _EnrollGuideBody({
    required this.notice,
    required this.busy,
    required this.onOpenSettings,
    required this.onConfirmed,
  });

  final String notice;
  final bool busy;
  final VoidCallback onOpenSettings;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title(context, l10n.bioEnrollTitle),
        SizedBox(height: 8.h),
        Text(
          l10n.bioPrivacyNote(AppConstants.appName),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        SizedBox(height: 20.h),
        _Step(number: 1, text: l10n.bioStep1),
        SizedBox(height: 14.h),
        _Step(number: 2, text: l10n.bioStep2),
        SizedBox(height: 14.h),
        _Step(number: 3, text: l10n.bioStep3),
        SizedBox(height: 14.h),
        _Step(number: 4, text: l10n.bioStep4),
        SizedBox(height: 20.h),
        if (notice.isNotEmpty) ...<Widget>[
          Text(
            notice,
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14.h),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onOpenSettings,
            icon: const Icon(Icons.settings_rounded),
            label: Text(l10n.bioOpenSettings),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: busy ? null : onConfirmed,
            child: Text(l10n.bioDoneEnrolled),
          ),
        ),
      ],
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.busy,
    required this.notice,
    required this.onEnable,
    required this.onBack,
  });

  final bool busy;
  final String notice;
  final VoidCallback onEnable;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title(context, l10n.bioReadyTitle),
        SizedBox(height: 8.h),
        Text(
          l10n.bioReadyBody(AppConstants.appName),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        SizedBox(height: 20.h),
        if (notice.isNotEmpty) ...<Widget>[
          Text(
            notice,
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 14.h),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onEnable,
            icon: busy
                ? SizedBox(
                    width: 18.w,
                    height: 18.h,
                    child: const CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.fingerprint_rounded),
            label: Text(
              busy ? AppLocalizations.of(context).verifying : l10n.bioTryNow,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: busy ? null : onBack,
            child: Text(l10n.chooseAnotherMethod),
          ),
        ),
      ],
    );
  }
}

class _UnsupportedBody extends StatelessWidget {
  const _UnsupportedBody({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _title(context, l10n.bioUnsupportedTitle),
        SizedBox(height: 8.h),
        Text(
          l10n.bioUnsupportedBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBack,
            child: Text(l10n.chooseAnotherMethod),
          ),
        ),
      ],
    );
  }
}

Widget _title(BuildContext context, String text) {
  return Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
  );
}
